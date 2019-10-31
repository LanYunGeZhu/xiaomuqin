//
//  LabelButtonView.swift
//  YMJF
//
//  Created by bin xie on 2018/1/25.
//  Copyright © 2018年 小木琴. All rights reserved.
//

import UIKit

class LabelButtonView: UIView {

    var callBackBtnAction:((Bool,Int)->())?
    var btnArr = [UIButton]()
    var isDrag = Bool()
    var isMin = Bool()
    var textColor = UIColor()
    var lineColor = UIColor()
    
    var btnTitleArr = NSArray() {
        
        didSet{
            setupBtnView(titleArr: btnTitleArr)
        }
    }
    
    lazy var columnsScrollView: UIScrollView = {
        let scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 44, width: bounds.width, height: bounds.height-44))
        scrollView.contentSize = CGSize.init(width: bounds.width * CGFloat(btnTitleArr.count), height: 0)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.bounces = true
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return scrollView
    }()
    
    lazy var lineView: UIView = {
        let tempView = UIView.init(frame: CGRect.init(x: 0, y: 41, width: 25, height: 3))
        tempView.backgroundColor = lineColor
        return tempView
    }()
    
    // pragma MARK: ------------- life cycle -------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// pragma MARK: ----------- getter/setter ------------

extension LabelButtonView {
    
    func setupBtnView(titleArr: NSArray) -> Void {
        
        for titleStr in titleArr
        {
            let index: Int = titleArr.index(of: titleStr)
            let btnWidth: CGFloat = isMin ? 100 : bounds.width / CGFloat(titleArr.count)
            let btnX: CGFloat = isMin ? (bounds.width - 200)/2 + btnWidth * CGFloat(index) : btnWidth * CGFloat(index)
            let columnsBtn: UIButton = UIButton(frame: CGRect(x: btnX, y: 0, width: btnWidth, height: 44))
            columnsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            let str: String = "\(titleArr[index])"
            columnsBtn.setTitle(str, for: .normal)
            columnsBtn.setTitleColor(UIColor.black, for: .normal)
            columnsBtn.setTitleColor(textColor, for: .selected)
            columnsBtn.addTarget(self, action: #selector(columnsBtnAction), for: .touchUpInside)
            columnsBtn.backgroundColor = UIColor.white
            addSubview(columnsBtn)
            columnsBtn.tag = index+100
            
            if index == 0
            {
                columnsBtn.isSelected = true
                self.columnsBtnAction(btn: columnsBtn)
            }
            
            btnArr.append(columnsBtn)
        }
        
        backgroundColor = UIColor.white
        addSubview(lineView)
        addSubview(columnsScrollView)
    }
}

// pragma MARK: -------------- Action ----------------

extension LabelButtonView {
    
    @objc func columnsBtnAction(btn: UIButton) -> Void {
        
        for subView in (btn.superview?.subviews)!
        {
            if subView.isKind(of: UIButton.self)
            {
                let allBtn: UIButton = (subView as? UIButton)!
                allBtn.isSelected = false
            }
        }
        
        btn.isSelected = true
        UIView.animate(withDuration: 0.3) {
            
            self.lineView.center = CGPoint.init(x: btn.center.x, y: self.lineView.center.y)
        }

        if !isDrag
        {
            columnsScrollView.setContentOffset(CGPoint.init(x: bounds.width * CGFloat(btn.tag-100), y: 0), animated: true)
        }
        
        isDrag = false
        callBackBtnAction?(btn.isSelected,btn.tag)
    }
    
    func selectedBtnIndex(index: Int) -> Void {
        
        for btn in btnArr
        {
            if btn.tag == 100+index
            {
                isDrag = false
                btn.isSelected = true
                columnsBtnAction(btn: btn)
            }
        }
    }
}

// pragma MARK: ------------- Delegate ---------------

extension LabelButtonView: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        // 设置拖拽时btn与scrollView下标对应
        let xOffset: CGFloat = scrollView.contentOffset.x
        let index: Int = Int(xOffset/bounds.width)
        
        for btn in btnArr
        {
            if btn.tag == 100+index
            {
                isDrag = true
                btn.isSelected = true
                columnsBtnAction(btn: btn)
            }
        }
    }
}
