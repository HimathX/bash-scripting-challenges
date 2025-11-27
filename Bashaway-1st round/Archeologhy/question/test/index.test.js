const fs = require('fs');
const tar = require('tar');
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
        await expect(dependencyCount()).resolves.toStrictEqual(5)
    });
});

test('should extract nested archives correctly', async () => {
    // Clean up
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    if (fs.existsSync('./out')) fs.rmSync('./out', { recursive: true });
    
    fs.mkdirSync('./src', { recursive: true });
    
    const secretMessage = faker.lorem.paragraph();
    const filename = `${faker.word.noun()}.txt`;
    
    // Create the innermost file
    const tempDir = './temp_test_archive';
    fs.mkdirSync(tempDir, { recursive: true });
    fs.writeFileSync(`${tempDir}/${filename}`, secretMessage);
    
    // Create nested archives (3 levels deep)
    await tar.c({ gzip: true, file: `${tempDir}/layer2.tar.gz`, cwd: tempDir }, [filename]);
    fs.unlinkSync(`${tempDir}/${filename}`);
    
    await tar.c({ gzip: true, file: `${tempDir}/layer1.tar.gz`, cwd: tempDir }, ['layer2.tar.gz']);
    fs.unlinkSync(`${tempDir}/layer2.tar.gz`);
    
    await tar.c({ gzip: true, file: `./src/archive.tar.gz`, cwd: tempDir }, ['layer1.tar.gz']);
    
    // Clean up temp directory
    fs.rmSync(tempDir, { recursive: true });
    
    // Execute the script
    await exec('bash execute.sh');
    
    // Check if the final file exists in out directory
    expect(fs.existsSync(`./out/${filename}`)).toBe(true);
    
    // Verify content
    const extractedContent = fs.readFileSync(`./out/${filename}`, 'utf-8');
    expect(extractedContent).toBe(secretMessage);
    
    // Verify no archive files remain in out
    const outFiles = fs.readdirSync('./out');
    const hasArchives = outFiles.some(file => file.endsWith('.tar.gz') || file.endsWith('.tar'));
    expect(hasArchives).toBe(false);
});

