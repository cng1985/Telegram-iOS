import UIKit
import SwiftSignalKit
import LegacyComponents
import Display
#if BUCK
import WebPImage
#else
import WebP
#endif

private func scaleImage(_ image: UIImage, dimensions: CGSize) -> UIImage? {
    if #available(iOSApplicationExtension 10.0, iOS 10.0, *) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: dimensions, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: dimensions))
        }
    } else {
        return TGScaleImageToPixelSize(image, dimensions)
    }
}

func convertToWebP(image: UIImage, targetSize: CGSize?, quality: CGFloat) -> Signal<Data, NoError> {
    var image = image
    if let targetSize = targetSize, let scaledImage = scaleImage(image, dimensions: targetSize) {
        image = scaledImage
    }
    
    return Signal { subscriber in
        if let data = try? WebP.convert(toWebP: image, quality: quality * 100.0) {
            subscriber.putNext(data)
        }
        subscriber.putCompletion()
        
        return EmptyDisposable
    } |> runOn(Queue.concurrentDefaultQueue())
}