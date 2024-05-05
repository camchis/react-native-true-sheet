import ExpoModulesCore

let events = ["onPresent", "onDismiss", "onSizeChange"]

public class ExpoBottomSheetModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoBottomSheet")
    
    View(ExpoBottomSheetView.self) {
      Events(events)
      
      Prop("name") { (view: ExpoBottomSheetView, prop: String) in
        print(prop)
      }
      
      AsyncFunction("presentAsync") { (view: ExpoBottomSheetView, promise: Promise) in
        view.present(at: 0, promise: promise)
      }
    }
  }
}
