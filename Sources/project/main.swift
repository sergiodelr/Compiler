let f = "/home/sergio/Documents/compis/exp.txt"
let scanner = Scanner(fileName: f)
let codeGenerator = CodeGenerator()
let parser = Parser(scanner: scanner, codeGenerator: codeGenerator)
parser.Parse()
codeGenerator.printQueue()
