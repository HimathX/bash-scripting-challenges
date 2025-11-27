const fs = require('fs');
const { faker } = require('@faker-js/faker');
const exec = require('@sliit-foss/actions-exec-wrapper').default;
const { scan, shellFiles, dependencyCount, restrictJavascript, restrictPython } = require('@sliit-foss/bashaway');

test('should validate if only bash files are present', () => {
    const shellFileCount = shellFiles().length;
    expect(shellFileCount).toBe(1);
    expect(shellFileCount).toBe(scan('**', ['src/**']).length);
});

describe('should check installed dependencies', () => {
    let script
    beforeAll(() => {
        script = fs.readFileSync('./execute.sh', 'utf-8')
    });
    test("javacript should not be used", () => {
        restrictJavascript(script)
    });
    test("python should not be used", () => {
        restrictPython(script)
    });
    test("no additional npm dependencies should be installed", async () => {
        await expect(dependencyCount()).resolves.toStrictEqual(4)
    });
    test('the script should be less than 35 characters in length', () => {
        expect(script.length).toBeLessThan(35);
    });
});

test('should count word occurrences across files', async () => {
    // Clean up
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    fs.mkdirSync('./src', { recursive: true });
    
    const targetWord = 'error';
    
    // Create files with known occurrences
    fs.writeFileSync('./src/file1.txt', `This is an error. Another error happened. error`);
    fs.writeFileSync('./src/file2.txt', `No issues here.`);
    fs.writeFileSync('./src/file3.txt', `error at line 1\nerror at line 2`);
    
    // Expected count: 5 (3 in file1, 0 in file2, 2 in file3)
    const output = await exec(`bash execute.sh ${targetWord}`);
    expect(Number(output?.trim())).toBe(5);
});

test('should be case-sensitive', async () => {
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    fs.mkdirSync('./src', { recursive: true });
    
    fs.writeFileSync('./src/test.txt', `error Error ERROR error`);
    
    // Only lowercase "error" should be counted (2 times)
    const output = await exec('bash execute.sh error');
    expect(Number(output?.trim())).toBe(2);
});

test('should count across multiple files', async () => {
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    fs.mkdirSync('./src', { recursive: true });
    
    const word = 'test';
    let expectedCount = 0;
    
    // Create multiple files with random occurrences
    for (let i = 0; i < 5; i++) {
        let content = '';
        const occurrences = faker.number.int({ min: 0, max: 5 });
        expectedCount += occurrences;
        
        for (let j = 0; j < occurrences; j++) {
            content += word + ' ' + faker.lorem.words() + ' ';
        }
        
        fs.writeFileSync(`./src/file${i}.txt`, content);
    }
    
    const output = await exec(`bash execute.sh ${word}`);
    expect(Number(output?.trim())).toBe(expectedCount);
});

test('should handle word boundaries correctly', async () => {
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    fs.mkdirSync('./src', { recursive: true });
    
    // Test that it counts whole words, not substrings
    fs.writeFileSync('./src/test.txt', `cat cats catch cat`);
    
    const output = await exec('bash execute.sh cat');
    // Should count 2 (the two standalone "cat"), not 4
    expect(Number(output?.trim())).toBe(2);
});

test('should return 0 when word not found', async () => {
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    fs.mkdirSync('./src', { recursive: true });
    
    fs.writeFileSync('./src/test.txt', `nothing to see here`);
    
    const output = await exec('bash execute.sh missing');
    expect(Number(output?.trim())).toBe(0);
});

