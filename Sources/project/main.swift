let f = "/home/sergio/Documents/compis/demo.txt"
let scanner = Scanner(fileName: f)
let gt = SymbolTable()
let parser = Parser(scanner: scanner, globalTable: gt)
parser.Parse()
