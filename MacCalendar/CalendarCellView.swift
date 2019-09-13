//
//  CalendarCellView.swift
//  MacCalendar
//
//  Created by bugcode on 16/8/17.
//  Copyright © 2016年 bugcode. All rights reserved.
//

import Cocoa

class CalendarCellView : NSButton, NSMenuDelegate{
    // 标识具体的cell
    var mCellID : Int = 0
    var mBgColor : NSColor = .white
    let mPopoverWindow = NSPopover()
    var mFlagView : CornerFlagView?
    // 当前是哪月
    var wzDay: CalendarUtils.WZDayTime = CalendarUtils.WZDayTime(0, 0, 0)
    // 当前是否是带标记日期
    var mIsFlagDate: Bool = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.cell = CalendarViewCell(coder: coder)

        self.isBordered = false
        self.wantsLayer = true
        self.layer!.backgroundColor = self.mBgColor.cgColor
        
        // 设置鼠标进出跟踪区域
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeAlways,NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    func setBackGroundColor(bgColor: NSColor) {
        self.mBgColor = bgColor
        self.wantsLayer = true
        self.layer!.backgroundColor = self.mBgColor.cgColor
    }
    
    // 关闭popover
    func performPopoverClose() {
        mPopoverWindow.performClose(nil)
        addFlagView(extraTip: "备", isShift: false, color: NSColor.blue)
    }
    
    // 弹出popover
    func showPopoverView(content: String) {
        let viewController = ReminderTipViewController(date: wzDay, view: self, content: content)
        mPopoverWindow.contentSize = viewController.view.fittingSize
        mPopoverWindow.contentViewController = viewController
        // 失去焦点时关闭
        mPopoverWindow.behavior = .transient
        mPopoverWindow.show(relativeTo: self.bounds, of: self, preferredEdge: NSRectEdge.minY)
    }
    
    // 添加日期标记
    @objc func addFlagHandler(_ sender:CalendarCellView) {
//        Swift.print("cur wzTime = \(wzDay.year)-\(wzDay.month)-\(wzDay.day)")
        showPopoverView(content: "")
    }
    // 移除日期标记
    @objc func removeFlagHandler(_ sender:CalendarCellView) {
//        Swift.print("cur wzTime = \(wzDay.year)-\(wzDay.month)-\(wzDay.day)")
        let dateStr = String(describing: wzDay.year) + String(describing: wzDay.month) + String(describing: wzDay.day)
        LocalDataManager.sharedInstance.removeData(forKey: dateStr)
        mFlagView?.removeFromSuperview()
    }
    // 在当前日期已有标记的情况下，显示编辑日期标志
    @objc func editFlagHandler(_ sender:CalendarCellView) {
        showPopoverView(content: LocalDataManager.sharedInstance.getCurDateFlag(wzDay: wzDay))
    }
    // 修改当前日期边框颜色
    func changeBorderColor(borderWid: CGFloat, color: NSColor) {
        if self.isEnabled {
            self.layer?.borderWidth = borderWid
            self.layer?.borderColor = color.cgColor
        }
    }
    
    // 创建右键菜单
    func createRightMouseMenu(_ event: NSEvent) {
        
        let popMenu = NSMenu()
        popMenu.delegate = self
        var addFlagItem = NSMenuItem(title: "添加提醒", action: #selector(CalendarCellView.addFlagHandler(_:)), keyEquivalent: "")
        
        let info = LocalDataManager.sharedInstance.getCurDateFlag(wzDay: wzDay)
        if info != "" {
            // 当前日期有标记
            addFlagItem = NSMenuItem(title: "编辑提醒", action: #selector(CalendarCellView.editFlagHandler(_:)), keyEquivalent: "")
            let removeFlagItem = NSMenuItem(title: "移除提醒", action: #selector(CalendarCellView.removeFlagHandler(_:)), keyEquivalent: "")
            popMenu.addItem(removeFlagItem)
        }
        popMenu.addItem(addFlagItem)

        NSMenu.popUpContextMenu(popMenu, with: event, for: self)
    }
    
    override func mouseExited(with event: NSEvent) {
        changeBorderColor(borderWid: 0, color: self.mBgColor)
    }
    
    override func mouseEntered(with event: NSEvent) {
        changeBorderColor(borderWid: 0.9, color: CalendarConstant.selectedDateColor)
    }
    
    // 右键点击格子弹出菜单
    override func rightMouseDown(with event: NSEvent) {
        // 显示右键菜单
        createRightMouseMenu(event)
    }
    
    // 添加标记子窗口
    func addFlagView(extraTip: String, isShift: Bool, color: NSColor) {
        let color = NSColor(calibratedRed: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0.6)
        if !isShift {
            mFlagView = CornerFlagView(color: color, frame: NSRect(x: 38, y: 0, width: 48, height: 15), extra: extraTip)
        } else {
            mFlagView = CornerFlagView(color: color, frame: NSRect(x: 0, y: 0, width: 48, height: 15), extra: extraTip)
        }
        
        addSubview(mFlagView!)
    }
    
    // 显示具体的农历和公历，设置具体button的标题属性
    func setString(wzTime: CalendarUtils.WZDayTime, topColor: NSColor, bottomText: String, bottomColor: NSColor) {
        
        wzDay = wzTime
        
        mFlagView?.removeFromSuperview()
        
        var isShift = false;

        if LocalDataManager.sharedInstance.isHoliday(wzTime: wzDay) {
            addFlagView(extraTip: "假", isShift: isShift, color: NSColor.purple)
            isShift = true
        } else if LocalDataManager.sharedInstance.isNeedWork(wzTime: wzDay) {
            addFlagView(extraTip: "班", isShift: isShift, color: NSColor.red)
            isShift = true
        }
        // 已标记过的日期，用橙色显示
        let info = LocalDataManager.sharedInstance.getCurDateFlag(wzDay: wzDay)
        if info != "" {
            addFlagView(extraTip: "备", isShift: isShift, color: NSColor.blue)
            self.toolTip = "备注: " + info
        }
        
        // 居中样式
        let style = NSMutableParagraphStyle()
        
        style.alignment = .center
        
        let topText = String(wzDay.day) + "\n"

        let goriDayDict = [NSAttributedString.Key.foregroundColor : topColor, NSAttributedString.Key.paragraphStyle : style, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 18.0)]
        let lunarDayDict = [NSAttributedString.Key.foregroundColor : bottomColor, NSAttributedString.Key.paragraphStyle : style, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 9.0)]
        
        let goriAttrDay = NSAttributedString(string: (topText as NSString).substring(with: NSMakeRange(0, topText.count)), attributes: goriDayDict)
        let lunarAttrDay = NSAttributedString(string: (bottomText as NSString).substring(with: NSMakeRange(0, bottomText.count)), attributes: lunarDayDict)

        let finalAttr = NSMutableAttributedString(attributedString: goriAttrDay)
        finalAttr.append(lunarAttrDay)
        
        self.attributedTitle = finalAttr
    }
    
    
}
