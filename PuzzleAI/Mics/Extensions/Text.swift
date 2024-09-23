
import SwiftUI

extension Text {
    enum TextStyleType {
        case descriptionBold
        case description
        case description2
        /// 12 / 500
        case descriptionSmall
        /// 16 / 600
        case button
        case secondaryButton
        /// 22 / 700
        case navigationTitle
        /// view title, coints
        /// 18 / 700
        case title
        /// section title, settings table
        /// 16 / 600
        case middle
        /// 12
        case small
        /// 36
        case biggest
        /// 32 / 700
        case bigDescription
        /// 32 / blue
        case bellowBigBlue
        ///white // 14 //500
        case `default`
        case defaultBoldBlue
        // 16 //600
        case defaultArticleBold
        case defaultBold
        
        var font:FontData {
            return switch self {
            case .descriptionSmall:
                    .systemFont(ofSize: 12, weight: .semibold)
            case .descriptionBold:
                    .systemFont(ofSize: 14, weight: .semibold)
            case .description, .description2:
                    .systemFont(ofSize: 14, weight: .medium)
            case .bigDescription: .systemFont(ofSize: 38, weight: .bold)
            case .bellowBigBlue: .systemFont(ofSize: 32, weight: .bold)
            case .small: .systemFont(ofSize: 12)
            case .biggest: .systemFont(ofSize: 36, weight: .bold)
            case .middle: .systemFont(ofSize: 16, weight: .regular)
            case .title: .systemFont(ofSize: 18, weight: .bold)
            case .navigationTitle: .systemFont(ofSize: 22, weight: .bold)
            case .secondaryButton, .button, .defaultArticleBold: .systemFont(ofSize: 16, weight: .semibold)
            case .defaultBold:
                    .systemFont(ofSize: 14, weight: .bold)
            default:.systemFont(ofSize: 14, weight: .semibold)
            }
            
        }
        
        var color:UIColor {
            return switch self {
            case .secondaryButton, .bellowBigBlue, .defaultBoldBlue:
                    .init(named: "blueTint")!
            case .description2:.descriptionText2
            case .descriptionBold, .description, .descriptionSmall, .bigDescription:
                    .descriptionText
            default: .title
            }
        }
        
        struct FontData {
            var size:Int
            var weight:Font.Weight
            
            init(size: Int, weight: Font.Weight) {
                self.size = size
                self.weight = weight
            }
            static func systemFont(ofSize:Int, weight:Font.Weight = .regular) -> FontData {
                return .init(size: ofSize, weight: weight)
            }
            var font:Font {
                return UIFont.custom(size: CGFloat(size), width: .systemWeight(self.weight))
            }
        }
    }
    
    func setStyle(_ type: TextStyleType = .default) -> some View {
        if type == .button || type == .secondaryButton {
            return self
                .basicStyle(type)
                .frame(maxWidth: .infinity)
        } else {
            return self
                .basicStyle(type)
                .frame(minWidth: .zero)
        }
    }
    
}

fileprivate extension View {
    func basicStyle(_ type: Text.TextStyleType = .default) -> some View {
        self
            .foregroundColor(Color(type.color))
            .font(type.font.font)
    }
}

extension UIFont {
    enum FontWeight:String, CaseIterable {
        case ultraLightItalic
        case ultraLight
        case thinItalic
        case thin
        case semiboldItalic
        case semibold
        case regularItalic
        case regular
        case mediumItalic
        case medium
        case lightItalic
        case light
        case heavyItalic
        case heavy
        case boldItalic
        case bold
        case blackItalic
        case black
        var name:String {
            return rawValue.capitalized
        }
        static func systemWeight(_ from:Font.Weight) -> FontWeight {
            return switch from {
            case .ultraLight:
                    .ultraLight
            case .ultraLight:
                    .ultraLight
            case .thin:
                    .thin
            case .semibold:
                    .semibold
            case .regular:
                    .regular
            case .medium:
                    .medium
            case .light:
                    .light
            case .heavy:
                    .heavy
            case .bold:
                    .bold
            case .black:
                    .black
            default:.regular
            }
        }
    }
    
    enum CustomFontName:String, CaseIterable {
        case `default` = "RedHatDisplay"
        
        var names:[String] {
            return switch self {
            default:
                [rawValue + "-"]
            }
        }
        var hasWidth:Bool {
            return switch self {
            case .default:true
            }
        }
    }
    
    static func custom(size:CGFloat, type:CustomFontName = .default, width:FontWeight? = nil) -> Font {
        
        var name = type.names.first(where: {
            var name = $0
            if type.hasWidth {
                name.append((width ?? .regular).name)
            }
            
            return UIFont(name: name, size: size) != nil
        }) ?? ""
        if type.hasWidth {
            name.append((width ?? .regular).name)
        }
        
        if let first:UIFont = .init(name:  name, size: size) {
            return .from(uiFont: first)
        } else {
#if DEBUG
            print("fontserror error ")
            for family in UIFont.familyNames {
                print("Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  Font: \(name)")
                }
            }
#endif
            return .system(size: size)
            
        }
    }
}

extension Font {
    static func from(uiFont: UIFont) -> Font {
        let ctFont = CTFontCreateWithName(uiFont.fontName as CFString, uiFont.pointSize, nil)
        return Font(ctFont)
    }
}

extension String {

    func stringArray(from:CharacterSet) -> [String] {
        return Array(self.unicodeScalars).filter( { from.contains($0)
        }).compactMap({
            "\($0)"
        })
    }
}
