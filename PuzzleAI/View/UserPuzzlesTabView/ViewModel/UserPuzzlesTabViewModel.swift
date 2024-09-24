//
//  UserPuzzlesTabViewModel.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

struct UserPuzzlesTabViewModel {
    var isPaidAI: Bool {
        DB.db.user?.aiPaid ?? false
    }
}
