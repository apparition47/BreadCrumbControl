//
//  Copyright 2015 Philippe Kersalé
//

import UIKit

let kStartButtonWidth:CGFloat = 44
let kBreadcrumbHeight:CGFloat = 44
let kBreadcrumbCover:CGFloat = 15


enum OperatorItem {
    case addItem
    case removeItem
}

public enum StyleBreadCrumb {
    case defaultFlatStyle
    case gradientFlatStyle
}

class ItemEvolution {
    var itemLabel: String = ""
    var operationItem: OperatorItem = OperatorItem.addItem
    var offsetX: CGFloat = 0.0
    init(itemLabel: String, operationItem: OperatorItem, offsetX: CGFloat) {
        self.itemLabel = itemLabel
        self.operationItem = operationItem
        self.offsetX = offsetX
    }
}

class EventItem {
    var itemsEvolution: [ItemEvolution]!
}



@IBDesignable
public class CBreadcrumbControl: UIControl{
    
    
    var _items: [String] = []
    public var _itemViews: [UIButton] = []

    public var containerView: UIView!
    public var startButton: UIButton!
    public var isButtonHeightFlexible = false
    
    var color: UIColor = UIColor.blue
    private var _animating: Bool = false
   
    private var animationInProgress: Bool = false
    
    // used if you send a new itemsBreadCrumb when "animationInProgress == true"
    private var itemsBCInWaiting: Bool = false

    // item selected
    public var itemClicked: String!
    public var itemPositionClicked: Int = -1

    func register() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedUINotificationNewItems), name:NSNotification.Name(rawValue: "NotificationNewItems"), object: nil)
    }
    
    
    @IBInspectable public var style: StyleBreadCrumb = .gradientFlatStyle {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    
    @IBInspectable public var visibleRootButton: Bool = true {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    
    @IBInspectable public var textBCColor: UIColor = UIColor.black {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    @IBInspectable public var backgroundRootButtonColor: UIColor = UIColor.white {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    @IBInspectable public var backgroundBCColor: UIColor = UIColor.clear {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    @IBInspectable public var itemPrimaryColor: UIColor = UIColor.gray {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    @IBInspectable public var offsetLastPrimaryColor: CGFloat = 16.0 {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    
    @IBInspectable public var animationSpeed: Double = 0.2 {
        didSet{
            initialSetup( refresh: true)
        }
    }
    
    
    @IBInspectable public var arrowColor: UIColor = UIColor.blue {
        didSet{
            //drawRect( self.frame)
            initialSetup( refresh: true)
        }
    }

    
    @IBInspectable public var itemsBreadCrumb: [String] = [] {
        didSet{
            if (!self.animationInProgress) {
                self.itemClicked = ""
                self.itemPositionClicked = -1
                initialSetup( refresh: false)
            } else {
                itemsBCInWaiting = true
            }
        }
    }
    
    @IBInspectable public var iconSize: CGSize = CGSize(width:20, height:20){
        didSet{
            //setNeedsDisplay()
            initialSetup( refresh: true)
        }
    }
    

    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        register()
        initialSetup( refresh: true)
    }
    

    override public init(frame: CGRect) {
        super.init(frame: frame)
        register()
        initialSetup( refresh: true)
    }

    
    func buttonHeight() -> CGFloat {
        if self.isButtonHeightFlexible {
            return self.frame.size.height
        } else {
            return kBreadcrumbHeight
        }
    }
    
    func initialSetup( refresh: Bool) {
        
        var changeRoot: Int = 0
        if ((visibleRootButton) && (self.startButton == nil)) {
            self.startButton = self.startRootButton()
            changeRoot = 1
        } else if ((visibleRootButton == false) && (self.startButton != nil)){
            changeRoot = 2
        }
        if (self.containerView == nil ) {
            let rectContainerView: CGRect = CGRect(origin: CGPoint(x:kStartButtonWidth+1, y:0), size: CGSize(width: self.bounds.size.width - (kStartButtonWidth+1), height: self.buttonHeight()))
            self.containerView = UIView(frame:rectContainerView)
            self.containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.addSubview( self.containerView)
        }

        self.containerView.backgroundColor = backgroundBCColor  //UIColor.white
        self.containerView.clipsToBounds = true
        if ((visibleRootButton) && (self.startButton != nil)) {
            self.startButton.backgroundColor = backgroundRootButtonColor
        }
        
        if (changeRoot == 1) {
            self.addSubview( self.startButton)
            let rectContainerView: CGRect = CGRect(origin: CGPoint(x:kStartButtonWidth+1, y:0), size:CGSize(width:self.bounds.size.width - (kStartButtonWidth+1), height:self.buttonHeight()))
            self.containerView.frame = rectContainerView
        } else if (changeRoot == 2) {
            self.startButton.removeFromSuperview()
            self.startButton = nil
            let rectContainerView: CGRect = CGRect(origin: CGPoint(x:0, y:0), size:CGSize(width:self.bounds.size.width, height:self.buttonHeight()))
            self.containerView.frame = rectContainerView
        }
        
        self.setItems( items: self.itemsBreadCrumb, refresh: refresh, containerView: self.containerView)
            
    }


    func startRootButton() -> UIButton
    {
        let button: UIButton = UIButton(type: UIButtonType.custom) as UIButton
        button.backgroundColor = backgroundRootButtonColor
        let bgImage : UIImage = UIImage(named: "button_start", in:Bundle(for: type(of: self)), compatibleWith: nil)!
        button.setBackgroundImage( bgImage, for: UIControlState.normal)
        button.frame = CGRect(origin: CGPoint(x:0, y:0), size:CGSize(width:kStartButtonWidth+1, height:self.buttonHeight()))
        button.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)

        return button
    }
    
    func itemButton( item: String, position: Int) -> BreadCrumbButton
    {
        let button: BreadCrumbButton = BreadCrumbButton() as BreadCrumbButton
        if (self.style == .gradientFlatStyle) {
            button.styleButton = .extendButton
            var red:CGFloat = 0, green:CGFloat = 0, blue:CGFloat = 0
            var rgbValueTmp = self.itemPrimaryColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
//            var rgbValueTmp = self.itemPrimaryColor.cgColor.components
//            let red = rgbValueTmp?[0]
//            let green = rgbValueTmp?[1]
//            let blue = rgbValueTmp?[1]
            //var rgbValue: Double = Double(rgbValueTmp)
            //var rgbValue = 0x777777
            //let rPrimary:CGFloat = CGFloat((rgbValue & 0xFF0000) >> 16)/255.0
            //let gPrimary:CGFloat = CGFloat((rgbValue & 0xFF00) >> 8)/255.0
            //let bPrimary:CGFloat = CGFloat((rgbValue & 0xFF))/255.0
            let rPrimary:CGFloat = CGFloat(red * 255.0)
            let gPrimary:CGFloat = CGFloat(green * 255.0)
            let bPrimary:CGFloat = CGFloat(blue * 255.0)

            
            let levelRedPrimaryColor: CGFloat = rPrimary + (self.offsetLastPrimaryColor * CGFloat(position))
            let levelGreenPrimaryColor: CGFloat = gPrimary + (self.offsetLastPrimaryColor * CGFloat(position))
            let levelBluePrimaryColor: CGFloat = bPrimary + (self.offsetLastPrimaryColor * CGFloat(position))
            let r = levelRedPrimaryColor/255.0
            let g = levelGreenPrimaryColor/255.0
            let b = levelBluePrimaryColor/255.0
            button.backgroundCustomColor =  UIColor(red:CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        } else {
            button.styleButton = .simpleButton
            button.backgroundCustomColor = self.backgroundBCColor  //self.backgroundItemColor
            button.arrowColor = self.arrowColor
        }
        button.contentMode = UIViewContentMode.center
        button.titleLabel!.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle(item, for:UIControlState.normal)
        button.setTitleColor( textBCColor, for: UIControlState.normal)
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        
        button.sizeToFit()
        let rectButton:CGRect = button.frame
        let widthButton: CGFloat = (position > 0) ? rectButton.width + 32 + kBreadcrumbCover : rectButton.width + 32
        button.frame = CGRect(origin:CGPoint(x:0, y:0), size:CGSize(width:widthButton , height:self.buttonHeight()))
        button.titleEdgeInsets = (position > 0) ? UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0) : UIEdgeInsets(top: 0.0, left: -kBreadcrumbCover, bottom: 0.0, right: 0.0)
        button.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
        
        return button
    }
    
    
    
    func pressed(sender: UIButton!) {
        let titleSelected = sender.titleLabel?.text
        if ((self.startButton != nil) && (self.startButton == sender)) {
            self.itemClicked = ""
            self.itemPositionClicked = 0
        } else {
            self.itemClicked = titleSelected
            for idx: Int in 0 ..< _items.count {
                if (titleSelected == _items[idx]) {
                    self.itemPositionClicked = idx + 1
                }
            }
        }
        self.sendActions( for: UIControlEvents.touchUpInside)
        
        /*
        let alertView = UIAlertView();
        alertView.addButtonWithTitle("Ok");
        alertView.title = "title";
        alertView.message = "message";
        alertView.show();
        */
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        
        var cx: CGFloat = 0  //kStartButtonWidth
        for var view: UIView in _itemViews
        {
            let s: CGSize = view.bounds.size
            view.frame = CGRect(origin:CGPoint(x:cx, y:0), size:CGSize(width:s.width, height:s.height))
            cx += s.width
        }
        initialSetup( refresh: true)
    }
    
    
    func singleLayoutSubviews( view: UIView, offsetX: CGFloat) {
        super.layoutSubviews()
        
        let s: CGSize = view.bounds.size
        view.frame = CGRect(origin:CGPoint(x:offsetX, y:0), size:CGSize(width:s.width, height:s.height))
    }
    
    
    func setItems(items: [String], refresh: Bool, containerView: UIView) {
        self.animationInProgress = true

        if (self._animating) {
            return
        }
        if (!refresh)
        {
            var itemsEvolution: [ItemEvolution] = [ItemEvolution]()
            // comparer with old items search the difference
            var endPosition: CGFloat = 0.0
            var idxToChange: Int = 0
            for idx: Int in 0 ..< _items.count {
                if ((idx < items.count) && (_items[idx] == items[idx])) {
                    idxToChange += 1
                    endPosition += _itemViews[idx].frame.width
                    continue
                } else {
                    endPosition -= _itemViews[idx].frame.width
                    if (itemsEvolution.count > idx) {
                    itemsEvolution.insert( ItemEvolution( itemLabel: items[idx], operationItem: OperatorItem.removeItem, offsetX: endPosition), at: idxToChange)
                    } else {
                        itemsEvolution.append(ItemEvolution( itemLabel: _items[idx], operationItem: OperatorItem.removeItem, offsetX: endPosition))
                    }
                }
            }
            for idx: Int in idxToChange ..< items.count {
                itemsEvolution.append( ItemEvolution( itemLabel: items[idx], operationItem: OperatorItem.addItem, offsetX: endPosition))
            }
            
            processItem( itemsEvolution: itemsEvolution, refresh: false)
        } else {
            self.animationInProgress = false
 
            var itemsEvolution: [ItemEvolution] = [ItemEvolution]()
            // comparer with old items search the difference
            let endPosition: CGFloat = 0.0
            for idx: Int in 0 ..< _items.count {
                itemsEvolution.append( ItemEvolution( itemLabel: items[idx], operationItem: OperatorItem.removeItem, offsetX: endPosition))
            }
            for idx: Int in 0 ..< _items.count {
                itemsEvolution.append( ItemEvolution( itemLabel: items[idx], operationItem: OperatorItem.addItem, offsetX: endPosition))
            }
            processItem( itemsEvolution: itemsEvolution, refresh: true)
        }
    }
    
    
    func processItem( itemsEvolution: [ItemEvolution], refresh: Bool) {
        //    _itemViews
        if (itemsEvolution.count > 0) {
            var itemsEvolutionToSend: [ItemEvolution] = [ItemEvolution]()
            for idx: Int in 1 ..< itemsEvolution.count {
                itemsEvolutionToSend.append( ItemEvolution( itemLabel: itemsEvolution[idx].itemLabel, operationItem: itemsEvolution[idx].operationItem, offsetX: itemsEvolution[idx].offsetX))
            }
            
            if (itemsEvolution[0].operationItem == OperatorItem.addItem) {
                //create a new UIButton
                var startPosition: CGFloat = 0
                var endPosition: CGFloat = 0
                if (_itemViews.count > 0) {
                    let indexTmp = _itemViews.count - 1
                    let lastViewShowing: UIView = _itemViews[indexTmp]
                    let rectLastViewShowing: CGRect = lastViewShowing.frame
                    endPosition = rectLastViewShowing.origin.x + rectLastViewShowing.size.width - kBreadcrumbCover
                }
                let label = itemsEvolution[0].itemLabel
                let itemButton: UIButton = self.itemButton( item: label, position: _itemViews.count)
                let widthButton: CGFloat = itemButton.frame.size.width
                startPosition = (_itemViews.count > 0) ? endPosition - widthButton - kBreadcrumbCover : endPosition - widthButton
                var rectUIButton = itemButton.frame
                rectUIButton.origin.x = startPosition;
                itemButton.frame = rectUIButton
                containerView.insertSubview( itemButton, at: 0)
                _itemViews.append(itemButton)
                _items.append( label)

                if (!refresh) {
                    UIView.animate( withDuration: self.animationSpeed, delay: 0, options:[.curveEaseInOut], animations: {
                        self.sizeToFit()
                        self.singleLayoutSubviews( view: itemButton, offsetX: endPosition)
                        } , completion: { finished in
                            self._animating = false
                            
                            if (itemsEvolution.count > 0) {
                                let eventItem: EventItem = EventItem()
                                eventItem.itemsEvolution = itemsEvolutionToSend
                                
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NotificationNewItems"), object: eventItem)
                            } else {
                                self.processIfItemsBreadCrumbInWaiting()  //self.animationInProgress = false
                            }
                    })
                } else {
                    self.sizeToFit()
                    self.singleLayoutSubviews( view: itemButton, offsetX: endPosition)
                    if (itemsEvolution.count > 0) {
                        processItem( itemsEvolution: itemsEvolutionToSend, refresh: true)
                    } else {
                        self.processIfItemsBreadCrumbInWaiting()  //self.animationInProgress = false
                    }
                }
            } else {
                
                //create a new UIButton
                var startPosition: CGFloat = 0
                var endPosition: CGFloat = 0
                if (_itemViews.count == 0) {
                    return
                }
                
                let indexTmp = _itemViews.count - 1
                let lastViewShowing: UIView = _itemViews[indexTmp]
                let rectLastViewShowing: CGRect = lastViewShowing.frame
                startPosition = rectLastViewShowing.origin.x
                let widthButton: CGFloat = lastViewShowing.frame.size.width
                endPosition = startPosition - widthButton
                var rectUIButton = lastViewShowing.frame
                rectUIButton.origin.x = startPosition;
                lastViewShowing.frame = rectUIButton
                
                
                if (!refresh) {
                    UIView.animate( withDuration: self.animationSpeed, delay: 0, options:[.curveEaseInOut], animations: {
                        self.sizeToFit()
                        self.singleLayoutSubviews( view: lastViewShowing, offsetX: endPosition)
                        } , completion: { finished in
                            self._animating = false
                            
                            lastViewShowing.removeFromSuperview()
                            self._itemViews.removeLast()
                            self._items.removeLast()

                            
                            if (itemsEvolution.count > 0) {
                                let eventItem: EventItem = EventItem()
                                eventItem.itemsEvolution = itemsEvolutionToSend
                                
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NotificationNewItems"), object: eventItem)
                            } else {
                                self.processIfItemsBreadCrumbInWaiting()  //self.animationInProgress = false
                            }
                    })
                } else {
                    self.sizeToFit()
                    self.singleLayoutSubviews( view: lastViewShowing, offsetX: endPosition)
                    lastViewShowing.removeFromSuperview()
                    self._itemViews.removeLast()
                    self._items.removeLast()
                    if (itemsEvolution.count > 0) {
                        processItem( itemsEvolution: itemsEvolutionToSend, refresh: true)
                    } else {
                        self.processIfItemsBreadCrumbInWaiting()  //self.animationInProgress = false
                    }
                }

            }
        } else {
            self.processIfItemsBreadCrumbInWaiting()  //self.animationInProgress = false
        }
    }
    
    func receivedUINotificationNewItems(notification: NSNotification){
        let event: AnyObject? = notification.object as AnyObject?
        let eventItems: EventItem? = event as? EventItem
        processItem( itemsEvolution: eventItems!.itemsEvolution, refresh: false)
    }

    func processIfItemsBreadCrumbInWaiting() {
        self.animationInProgress = false
        if (itemsBCInWaiting == true) {
            itemsBCInWaiting = false
            self.itemClicked = ""
            initialSetup( refresh: false)
        }
    }

    
}
