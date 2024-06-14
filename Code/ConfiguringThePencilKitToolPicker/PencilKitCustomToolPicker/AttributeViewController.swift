/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for the attribute area in the property popover.
*/

import UIKit

class AttributeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    let attributeModel: AttributeViewController.Model
    var collectionView: UICollectionView?
    lazy var viewHeight = 50.0
    lazy var margin = 7.0
    lazy var cellHeight = viewHeight - (margin * 2)

    init(attributeModel: AttributeViewController.Model) {
        self.attributeModel = attributeModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        collectionView?.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 200, height: viewHeight)
        view.backgroundColor = .clear

        // Creates a `UICollectionView` with a horizontal scroll layout.
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")

        self.collectionView = collectionView
        view.addSubview(collectionView)

        // Sets constraints for the collection view.
        let topConstraint = NSLayoutConstraint(item: collectionView,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: view,
                                               attribute: .top,
                                               multiplier: 1.0,
                                               constant: margin)
        
        let bottomConstraint = NSLayoutConstraint(item: collectionView,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: view,
                                                  attribute: .bottom,
                                                  multiplier: 1.0,
                                                  constant: -margin)

        let leadingConstraint = NSLayoutConstraint(item: collectionView,
                                                   attribute: .leading,
                                                   relatedBy: .equal,
                                                   toItem: view,
                                                   attribute: .leading,
                                                   multiplier: 1.0,
                                                   constant: margin)

        let trailingConstraint = NSLayoutConstraint(item: collectionView,
                                                    attribute: .trailing,
                                                    relatedBy: .equal,
                                                    toItem: view,
                                                    attribute: .trailing,
                                                    multiplier: 1.0,
                                                    constant: -margin)

        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint
        ])
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attributeModel.attributes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        let name = attributeModel.attributes[indexPath.item].name
        let currentImage = attributeModel.attributes[indexPath.item].image
        let image = attributeModel.shouldApplyColor ? currentImage.withTintColor(attributeModel.color, renderingMode: .alwaysOriginal) : currentImage

        let frame = CGRect(x: 0, y: 0, width: cellHeight, height: cellHeight)
        let button = SelectButton(frame: frame, name: name, image: image) { name in
            self.attributeModel.selectedAttribute = (name: name, image: image)
        }
        button.contentMode = .scaleAspectFit
        button.setSelected( name == attributeModel.selectedAttribute.name)

        cell.addSubview(button)

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellHeight, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}

extension AttributeViewController {
    typealias AttributeType = (name: String, image: UIImage)

    class Model {
        var shouldApplyColor = true
        var attributes: [AttributeType] = []
        var previousSelectedAttribute: AttributeType?
        var selectedAttribute: AttributeType {
            didSet {
                if selectedAttribute.name != previousSelectedAttribute?.name {
                    selectedAttributeDidChange?(selectedAttribute)
                }
            }
        }

        var selectedImage: UIImage? {
            selectedAttribute.image
        }
        var color: UIColor = .black
        var selectedAttributeDidChange: ((AttributeType) -> Void)?

        init(attributes: [(name: String, image: UIImage)], selectedAttribute: AttributeType, color: UIColor) {
            self.attributes = attributes
            self.selectedAttribute = selectedAttribute
            self.color = color
        }
    }
}

fileprivate extension AttributeViewController {

    class Cell: UICollectionViewCell {
        var customSubview: UIView?

        override func addSubview(_ view: UIView) {
            super.addSubview(view)
            self.customSubview = view
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            customSubview?.removeFromSuperview()
        }
    }

    /// A button for presenting and selecting attributes.
    class SelectButton: UIButton {

        typealias ActionClosure = (String) -> Void
        
        let name: String
        var action: ActionClosure?

        init(frame: CGRect, name: String, image: UIImage, action: ActionClosure? = nil) {
            self.name = name
            self.action = action
            super.init(frame: frame)
            setImage(image, for: .normal)
            addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func buttonTapped() {
            action?(name)
        }

        func setSelected(_ isSelected: Bool) {
            if isSelected {
                addBorder(color: .gray, width: 2, cornerRadius: 10)
            } else {
                removeBorder()
            }
        }

        func removeBorder() {
            self.layer.borderColor = nil
            self.layer.borderWidth = 0
            self.clipsToBounds = false
        }

        func addBorder(color: UIColor, width: CGFloat, cornerRadius: CGFloat) {
            self.layer.borderColor = color.cgColor
            self.layer.borderWidth = width
            self.layer.cornerRadius = cornerRadius
            self.clipsToBounds = false
        }
    }
}
