import Foundation

/// Seed catalog of popular cigars. Public product names only —
/// future versions should pull from a server-side catalog table so
/// it can be updated without shipping a new build.
enum CigarCatalog {
    static let all: [Cigar] = [
        .new("Arturo Fuente", "OpusX", "Perfecxion No. 2"),
        .new("Arturo Fuente", "Hemingway", "Short Story"),
        .new("Arturo Fuente", "Don Carlos", "No. 3"),
        .new("Ashton", "VSG", "Sorcerer"),
        .new("Ashton", "Classic", "Churchill"),
        .new("Cohiba", "Behike", "BHK 52"),
        .new("Cohiba", "Siglo", "VI"),
        .new("Davidoff", "Nicaragua", "Toro"),
        .new("Davidoff", "Winston Churchill", "The Late Hour"),
        .new("Drew Estate", "Liga Privada", "No. 9 Toro"),
        .new("Drew Estate", "Undercrown", "Sun Grown"),
        .new("Montecristo", "No. 2", "Torpedo"),
        .new("Oliva", "Serie V", "Melanio"),
        .new("Padron", "1964 Anniversary", "Exclusivo"),
        .new("Padron", "1926 Series", "No. 9"),
        .new("Padron", "Family Reserve", "No. 45"),
        .new("Romeo y Julieta", "Churchill", "Añejo"),
        .new("Rocky Patel", "Decade", "Toro"),
        .new("My Father", "Le Bijou 1922", "Torpedo Box Pressed"),
        .new("Tatuaje", "Havana VI", "Verocu No. 9"),
        .new("Illusione", "Epernay", "Le Petit"),
        .new("Hoyo de Monterrey", "Epicure", "No. 2"),
        .new("Partagas", "Serie D", "No. 4"),
        .new("Caldwell", "Long Live the King", "Robusto"),
        .new("Crowned Heads", "Le Carema", "Toro"),
        .new("La Flor Dominicana", "Double Ligero", "Chisel"),
        .new("Alec Bradley", "Prensado", "Churchill"),
        .new("Perdomo", "20th Anniversary", "Maduro Epicure"),
        .new("E.P. Carrillo", "La Historia", "E-III"),
        .new("CAO", "Flathead", "V660"),
        .new("Viaje", "Exclusivo", "Nicaragua"),
        .new("Diesel", "Whiskey Row", "Robusto")
    ]
}

private extension Cigar {
    static func new(_ brand: String, _ line: String, _ vitola: String?) -> Cigar {
        Cigar(id: UUID(), brand: brand, line: line, vitola: vitola)
    }
}
