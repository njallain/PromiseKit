//
//  CoreData+Promise.swift
//  PromiseKit
//
//  Created by Neil Allain on 11/22/18.
//

import Foundation
import CoreData


@available(iOS 10.0, macOS 10.12, *)
extension NSPersistentContainer {
	public func loadPersistentStoresAsync() -> Promise<Void> {
		let (promise, seal) = Promise<Void>.pending()
		var expectedCount = 1
		if (expectedCount == 0) {
			seal.fulfill(())
		}
		self.loadPersistentStores { store, err in
			expectedCount -= 1
			if let err = err {
				seal.reject(err)
			}
			if expectedCount <= 0 {
				seal.fulfill(())
			}
		}
		return promise
	}
}

extension NSManagedObjectContext {
	public func saveAsync() -> Promise<Void> {
		return self.performAsync { try self.save() }
	}
	public func executeAsync<T>(fetch: NSFetchRequest<T>) -> Promise<[T]> {
		let (promise, seal) = Promise<[T]>.pending()
		let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetch) { result in
			guard let fetched = result.finalResult else {
				seal.reject(result.operationError ?? NSError(domain: "Prio", code: -1))
				return
			}
			seal.fulfill(fetched)
		}
		self.perform {
			do {
				try self.execute(asyncFetch)
			} catch {
				seal.reject(error)
			}
		}
		return promise
	}
	
	public func performAsync<T>(_ block: @escaping () throws -> T) -> Promise<T> {
		let (promise, seal) = Promise<T>.pending()
		self.perform {
			do {
				let result = try block()
				seal.fulfill(result)
			} catch {
				seal.reject(error)
			}
		}
		return promise
	}
}
