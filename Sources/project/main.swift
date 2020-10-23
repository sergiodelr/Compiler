let f = "/home/sergio/Documents/compis/demo.txt"
let scanner = Scanner(fileName: f)
let codeGenerator = CodeGenerator()
let parser = Parser(scanner: scanner, codeGenerator: codeGenerator)
parser.Parse()
