if CommandLine.arguments.count == 3 {
    let filePath = CommandLine.arguments[1]
    let outputPath = CommandLine.arguments[2]
    let scanner = Scanner(fileName: filePath)
    let codeGenerator = CodeGenerator()
    let parser = Parser(scanner: scanner, codeGenerator: codeGenerator)
    parser.Parse()
    if(parser.errors.count == 0) {
        parser.save(toPath: outputPath)
    }
} else {
    print("Expected two arguments: file path, output path.")
}

