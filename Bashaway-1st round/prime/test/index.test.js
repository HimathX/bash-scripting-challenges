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

test('should correctly identify prime numbers', async () => {
    const isPrime = (num) => {
        if (num <= 1) return 'Neither';
        if (num === 2) return 'Prime';
        if (num % 2 === 0) return 'Composite';
        for (let i = 3; i * i <= num; i += 2) {
            if (num % i === 0) return 'Composite';
        }
        return 'Prime';
    };

    const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97];
    const composites = [4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30];
    const neither = [0, 1, -1, -5, -10];

    // Test primes
    for (const num of primes) {
        const output = await exec(`bash execute.sh ${num}`);
        expect(output?.trim()).toBe('Prime');
    }

    // Test composites
    for (const num of composites) {
        const output = await exec(`bash execute.sh ${num}`);
        expect(output?.trim()).toBe('Composite');
    }

    // Test neither
    for (const num of neither) {
        const output = await exec(`bash execute.sh ${num}`);
        expect(output?.trim()).toBe('Neither');
    }
});

test('should handle random numbers correctly', async () => {
    const isPrime = (num) => {
        if (num <= 1) return 'Neither';
        if (num === 2) return 'Prime';
        if (num % 2 === 0) return 'Composite';
        for (let i = 3; i * i <= num; i += 2) {
            if (num % i === 0) return 'Composite';
        }
        return 'Prime';
    };

    for (let i = 0; i < 20; i++) {
        const num = faker.number.int({ min: 2, max: 500 });
        const output = await exec(`bash execute.sh ${num}`);
        expect(output?.trim()).toBe(isPrime(num));
    }
});

