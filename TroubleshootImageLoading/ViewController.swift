//
//  ViewController.swift
//  TroubleshootImageLoading
//
//  Created by Bertrand HOLVECK on 06/12/2016.
//  Copyright © 2016 HOLVECK Ingénieries. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    var objCTests: ObjectiveCTests?
    var imageAsset: PHAsset? {
        didSet {
            DispatchQueue.main.async {
                self.testButtonsView.enableAllButtons(self.imageAsset != nil)
            }
        }
    }

    var numberOfPHAssetFetches: Int = 0 {
        didSet {
            if numberOfPHAssetFetches == 1000 {
                completion(true)
            }
        }
    }

    @IBOutlet weak var testButtonsView: UIView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var executeInDispatchQueueSwitch: UISwitch!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //! Initialization. We just get one PHAsset from the user's Photos Library
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            let allImagesOptions = PHFetchOptions()
            allImagesOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            allImagesOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.imageAsset = PHAsset.fetchAssets(with: allImagesOptions).firstObject
        }
    }

    //! This is the completion task that called at the end of each test
    func completion(_ success: Bool) {
        DispatchQueue.main.async {
            print("DONE")
            self.activity.stopAnimating()
            self.testButtonsView.isHidden = false
        }
    }

    /*!
     * This is a wrapper for executing the run task in a dispatch queue or not, depending on the
     * UISwitch state.
     */
    func execute(_ run: @escaping () -> Void) {
        if executeInDispatchQueueSwitch.isOn {
            let queue = DispatchQueue(label: "myQueue")
            queue.async {
                run()
            }
        } else {
            run()
        }
    }


    /*!
     * The first test shows the architecture in which I encountered the issue. Some Swift code calls
     * Objective-C code in which I load an image from some PHAssets. Note that in my "real" project
     * I don't open a single asset for a thousand times. Instead I load images from 300+ different
     * PHAssets. So the issue as no link with the fact that I use one single asset for this test.
     */
    @IBAction func testOne() {
        if let imageAsset = imageAsset {
            testButtonsView.isHidden = true
            activity.startAnimating()

            objCTests = ObjectiveCTests(with: imageAsset)

            execute() {
                self.objCTests?.testOne(completion: self.completion)
            }
        }
    }

    /*!
     * The second test shows something I went trough while troubleshooting, and is only possible to
     * test in Obj-C. It shows that if we CFRelease the CGDataProvider, the memory doesn't grow. But
     * as we are not supposed, at end of the loop, all the thousand CGDataProviders are CFReleased
     * and then the app crashes as this results in double frees.
     */
    @IBAction func testTwo() {
        if let imageAsset = imageAsset {
            testButtonsView.isHidden = true
            activity.startAnimating()

            objCTests = ObjectiveCTests(with: imageAsset)

            execute() {
                self.objCTests?.testTwo(completion: self.completion)
            }
        }
    }

    /*!
     * The purpose of this test is to show that when testOne is implemented in swift, the same
     * behavior happens. This has nothing to do with using Obj-C.
     */
    @IBAction func testThree() {
        if let imageAsset = imageAsset {
            testButtonsView.isHidden = true
            activity.startAnimating()

            execute() {
                let imRequestOptions = PHImageRequestOptions()
                imRequestOptions.resizeMode = .fast
                imRequestOptions.deliveryMode = .opportunistic
                imRequestOptions.isSynchronous = true
                imRequestOptions.isNetworkAccessAllowed = true

                for _ in 0..<1000 {
                    print(".", terminator: "")
                    var image: UIImage?

                    PHImageManager.default().requestImage(for: imageAsset, targetSize: CGSize(width: 640, height: 480), contentMode: .aspectFill, options: imRequestOptions) {
                        theImage, _ in
                        image = theImage
                    }

                    let provider = image?.cgImage?.dataProvider
                    var _ = provider?.data
                }

                self.completion(true)
            }
        }
    }


    /*!
     * The purpose of this test is to show that when the image data is not mapped, the image is
     * correctly released at end of loop. It was obvious after testTwo showed that the issue
     * relates with CGDataProvider.
     */
    @IBAction func testFour() {
        if let imageAsset = imageAsset {
            testButtonsView.isHidden = true
            activity.startAnimating()

            execute() {
                let imRequestOptions = PHImageRequestOptions()
                imRequestOptions.resizeMode = .fast
                imRequestOptions.deliveryMode = .opportunistic
                imRequestOptions.isSynchronous = true
                imRequestOptions.isNetworkAccessAllowed = true

                for _ in 0..<1000 {
                    print(".", terminator: "")
                    var image: UIImage?

                    PHImageManager.default().requestImage(for: imageAsset, targetSize: CGSize(width: 640, height: 480), contentMode: .aspectFill, options: imRequestOptions) {
                        theImage, _ in
                        image = theImage
                    }

                    print("\(image!.size)") // just to make sure the compiler doesn't simplify the code by removing variable image
                }

                self.completion(true)
            }
        }
    }


    /*!
     * Test Five is here to show that the issue has nothing to do with the fact that the image is
     * accessed outside of the PHImageManager requestImage's result handler.
     */
    @IBAction func testFive() {
        if let imageAsset = imageAsset {
            testButtonsView.isHidden = true
            activity.startAnimating()

            execute() {
                let imRequestOptions = PHImageRequestOptions()
                imRequestOptions.resizeMode = .fast
                imRequestOptions.deliveryMode = .opportunistic
                imRequestOptions.isSynchronous = true
                imRequestOptions.isNetworkAccessAllowed = true

                for _ in 0..<1000 {
                    print(".", terminator: "")

                    PHImageManager.default().requestImage(for: imageAsset, targetSize: CGSize(width: 640, height: 480), contentMode: .aspectFill, options: imRequestOptions) {
                        theImage, _ in
                        let provider = theImage?.cgImage?.dataProvider
                        var _ = provider?.data
                    }
                }

                self.completion(true)
            }
        }
    }


    /*!
     * Test Six is here to show that it seems to work correctly when fetch is asynchronous. It seems
     * expected, as we can see that in the previous tests, the memory is kept mapped for the life of
     * the loop, and as in this sixth test the loop is asynchronous, the memory management shouldn't
     * be linked to the loop itself.
     */
    @IBAction func testSix() {
        if let imageAsset = imageAsset {
            testButtonsView.isHidden = true
            activity.startAnimating()

            self.numberOfPHAssetFetches = 0

            execute() {
                let imRequestOptions = PHImageRequestOptions()
                imRequestOptions.resizeMode = .fast
                imRequestOptions.deliveryMode = .opportunistic
                imRequestOptions.isSynchronous = false
                imRequestOptions.isNetworkAccessAllowed = true

                for _ in 0..<1000 {
                    DispatchQueue.main.async {
                        print(".", terminator: "")
                    }

                    PHImageManager.default().requestImage(for: imageAsset, targetSize: CGSize(width: 640, height: 480), contentMode: .aspectFill, options: imRequestOptions) {
                        theImage, info in
                        if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded == false {
                            let provider = theImage?.cgImage?.dataProvider
                            var _ = provider?.data

                            DispatchQueue.main.async {
                                self.numberOfPHAssetFetches += 1
                            }
                        }
                    }
                }
            }
        }
    }


    /*!
     * The purpose of this test is to show that the same behavior can be shown whithout Photos
     * framework.
     * In this case we load the data as NSData from an image in the app bundle, then read it to
     * convert it into an UIImage. Same behavior happens. Note that it also illustrates that the
     * issue is not necessarily linked to CGDataProvider.
     */
    @IBAction func testSeven() {
        testButtonsView.isHidden = true
        activity.startAnimating()

        execute() {
            var imageURL: URL?
            imageURL = Bundle.main.resourceURL?.appendingPathComponent("myimage.jpg")

            if let imageURL = imageURL {
                for _ in 0..<1000 {
                    print(".", terminator: "")

                    var imageData: Data?
                    do {
                        imageData = try Data(contentsOf: imageURL)
                    } catch let error as NSError {
                        print(error.localizedDescription)
                        return
                    }
                    // Note that the memory issue happens also when imagedata is accessed using CGData
                    let _ = UIImage(data: imageData!)
                }
            }

            self.completion(true)
        }
    }


    /*!
     * The purpose of this test is to show that if the data is not used it is released at each loop.
     */
    @IBAction func testEight() {
        testButtonsView.isHidden = true
        activity.startAnimating()

        execute() {
            var imageURL: URL?
            imageURL = Bundle.main.resourceURL?.appendingPathComponent("myimage.jpg")

            if let imageURL = imageURL {
                for _ in 0..<1000 {
                    print(".", terminator: "")

                    var imageData: Data?
                    do {
                        imageData = try Data(contentsOf: imageURL)
                    } catch let error as NSError {
                        print(error.localizedDescription)
                        break
                    }

                    print("\(imageData?.count)") // just to make sure the compiler doesn't simplify the code by removing variable image
                }
            }

            self.completion(true)
        }
    }


    /*!
     * Test nine aims to show that if the image is directly loaded from disk using UIImage
     * constructor (instead of loading it as Data and then creating a UIImage), the memory is again
     * correctly released at each loop. Does this mean that the issue has something to do with
     * Data/NSData/CGData?
     */
    @IBAction func testNine() {
        testButtonsView.isHidden = true
        activity.startAnimating()

        execute() {
            var imageURL: URL?
            imageURL = Bundle.main.resourceURL?.appendingPathComponent("myimage.jpg")

            if let imageURL = imageURL {
                for _ in 0..<1000 {
                    print(".", terminator: "")

                    let image = UIImage(contentsOfFile: imageURL.path)
                    print("\(image!.size)") // just to make sure the compiler doesn't simplify the code by removing variable image
                }
            }

            self.completion(true)
        }
    }


    /*!
     * The purpose of this test is to show that if the image is directly loaded from disk using
     * UIImage constructor and then its data is accessed as in tests One and Two, the memory
     * is again released at each loop. So does it really have something to do with
     * Data/NSData/CGData?
     */
    @IBAction func testTen() {
        testButtonsView.isHidden = true
        activity.startAnimating()

        execute() {
            var imageURL: URL?
            imageURL = Bundle.main.resourceURL?.appendingPathComponent("myimage.jpg")

            if let imageURL = imageURL {
                for _ in 0..<1000 {
                    print(".", terminator: "")

                    let image = UIImage(contentsOfFile: imageURL.path)
                    let provider = image?.cgImage?.dataProvider
                    var _ = provider?.data
                }
            }

            self.completion(true)
        }
    }

}

