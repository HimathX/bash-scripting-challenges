const fs = require('fs');
const exec = require('@sliit-foss/actions-exec-wrapper').default;
const { scan, shellFiles, dependencyCount, restrictJavascript, restrictPython } = require('@sliit-foss/bashaway');

jest.setTimeout(30000);

test('should validate if only bash files are present', () => {
    const shellFileCount = shellFiles().length;
    expect(shellFileCount).toBe(1);
    expect(shellFileCount).toBe(scan('**', ['src/**']).length);
});

describe('should check installed dependencies', () => {
    let script;
    beforeAll(() => {
        script = fs.readFileSync('./execute.sh', 'utf-8');
    });
    test("javacript should not be used", () => {
        restrictJavascript(script);
    });
    test("python should not be used", () => {
        restrictPython(script);
    });
    test("no additional npm dependencies should be installed", async () => {
        await expect(dependencyCount()).resolves.toStrictEqual(4);
    });
});

test('should resolve dependencies and generate graph', async () => {
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    if (fs.existsSync('./out')) fs.rmSync('./out', { recursive: true });
    
    fs.mkdirSync('./src/pkgA', { recursive: true });
    fs.mkdirSync('./src/pkgB', { recursive: true });
    fs.mkdirSync('./src/pkgC', { recursive: true });
    
    fs.writeFileSync('./src/pkgA/package.json', JSON.stringify({
        name: 'pkgA',
        dependencies: { 'pkgB': '1.0.0' }
    }));
    
    fs.writeFileSync('./src/pkgB/package.json', JSON.stringify({
        name: 'pkgB',
        dependencies: { 'pkgC': '1.0.0' }
    }));
    
    fs.writeFileSync('./src/pkgC/package.json', JSON.stringify({
        name: 'pkgC',
        dependencies: {}
    }));
    
    await exec('bash execute.sh');
    
    expect(fs.existsSync('./out/graph.json')).toBe(true);
    expect(fs.existsSync('./out/order.txt')).toBe(true);
    
    const graph = JSON.parse(fs.readFileSync('./out/graph.json', 'utf-8'));
    expect(graph).toHaveProperty('pkgA');
    expect(graph).toHaveProperty('pkgB');
    expect(graph).toHaveProperty('pkgC');
    
    const order = fs.readFileSync('./out/order.txt', 'utf-8').split('\n').filter(l => l);
    expect(order).toContain('pkgC');
    expect(order).toContain('pkgB');
    expect(order).toContain('pkgA');
    
    // pkgC should come before pkgB, pkgB before pkgA
    expect(order.indexOf('pkgC')).toBeLessThan(order.indexOf('pkgB'));
    expect(order.indexOf('pkgB')).toBeLessThan(order.indexOf('pkgA'));
});

test('should detect circular dependencies', async () => {
    if (fs.existsSync('./src')) fs.rmSync('./src', { recursive: true });
    if (fs.existsSync('./out')) fs.rmSync('./out', { recursive: true });
    
    fs.mkdirSync('./src/pkgX', { recursive: true });
    fs.mkdirSync('./src/pkgY', { recursive: true });
    
    fs.writeFileSync('./src/pkgX/package.json', JSON.stringify({
        name: 'pkgX',
        dependencies: { 'pkgY': '1.0.0' }
    }));
    
    fs.writeFileSync('./src/pkgY/package.json', JSON.stringify({
        name: 'pkgY',
        dependencies: { 'pkgX': '1.0.0' }
    }));
    
    await exec('bash execute.sh');
    
    expect(fs.existsSync('./out/circular.txt')).toBe(true);
    
    const circular = fs.readFileSync('./out/circular.txt', 'utf-8');
    expect(circular.length).toBeGreaterThan(0);
});

