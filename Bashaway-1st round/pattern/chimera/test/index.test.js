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
});

test('should generate correct triangle pattern', async () => {
    const generatePattern = (n) => {
        let result = [];
        for (let i = 1; i <= n; i++) {
            const row = Array(i).fill('*').join(' ');
            result.push(row);
        }
        return result.join('\n');
    };

    const testCases = [1, 3, 5, 7, 10];

    for (const n of testCases) {
        const output = await exec(`bash execute.sh ${n}`);
        const expected = generatePattern(n);
        expect(output?.trim()).toBe(expected);
    }
});

test('should handle random numbers', async () => {
    const generatePattern = (n) => {
        let result = [];
        for (let i = 1; i <= n; i++) {
            const row = Array(i).fill('*').join(' ');
            result.push(row);
        }
        return result.join('\n');
    };

    for (let i = 0; i < 15; i++) {
        const n = faker.number.int({ min: 1, max: 20 });
        const output = await exec(`bash execute.sh ${n}`);
        const expected = generatePattern(n);
        expect(output?.trim()).toBe(expected);
    }
});

test('should not have trailing spaces', async () => {
    const n = 5;
    const output = await exec(`bash execute.sh ${n}`);
    const lines = output.split('\n').filter(l => l);
    
    for (const line of lines) {
        expect(line).not.toMatch(/\s$/); // No trailing whitespace
    }
});

test('should have correct spacing between asterisks', async () => {
    const output = await exec('bash execute.sh 4');
    const lines = output.trim().split('\n');
    
    expect(lines[0]).toBe('*');
    expect(lines[1]).toBe('* *');
    expect(lines[2]).toBe('* * *');
    expect(lines[3]).toBe('* * * *');
});

