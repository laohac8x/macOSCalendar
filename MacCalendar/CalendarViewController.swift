//
//  CalendarViewController.swift
//  MacCalendar
//
//  Created by bugcode on 16/7/16.
//  Copyright © 2016年 bugcode. All rights reserved.
//

import Cocoa

class CalendarViewController: NSWindowController, NSTextFieldDelegate {
    
    
    // MARK: - Outlets define
    // 周末二个标签
    @IBOutlet weak var saturdayLabel: NSTextField!
    @IBOutlet weak var sundayLabel: NSTextField!
    
    // 右下角生肖图片
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var poemLabel: NSTextField!
    @IBOutlet weak var nextPoemLabel: NSTextField!
    // 设置按钮
    @IBOutlet weak var settingBtn: NSButton!
    
    // 年和月上的箭头
    @IBOutlet weak var nextYearBtn: NSButton!
    @IBOutlet weak var lastYearBtn: NSButton!
    @IBOutlet weak var nextMonthBtn: NSButton!
    @IBOutlet weak var lastMonthBtn: NSButton!
    
    // 顶部三个label
    @IBOutlet weak var yearText: CalendarTextField!
    @IBOutlet weak var monthText: CalendarTextField!
    
    // 右侧显示区
    @IBOutlet weak var dateDetailLabel: NSTextField!
    @IBOutlet weak var dayLabel: NSTextField!

    @IBOutlet weak var lunarDateLabel: NSTextField!
    @IBOutlet weak var lunarYearLabel: NSTextField!
    @IBOutlet weak var holidayLabel: NSTextField!
    
    @IBOutlet weak var pinNote: NSTextField!
    // 日历类实例
    private var mCalendar: LunarCalendarUtils = LunarCalendarUtils()
    private var mPreCalendar: LunarCalendarUtils = LunarCalendarUtils()
    private var mNextCalendar: LunarCalendarUtils = LunarCalendarUtils()

    private var mCurMonth: Int = 0
    private var mCurDay: Int = 0
    private var mCurYear: Int = 0
    // 每个显示日期的单元格
    private var cellBtns = [CalendarCellView]()
    private var lastRowNum:Int = 0
    
    private var lastPressBtn: CalendarCellView?
    
    // 下一个节日的名字
    @IBOutlet weak var nextHolidayTip: NSTextField!
    
    @IBOutlet weak var nextHolidayDays: NSTextField!
    override var windowNibName: NSNib.Name?{
        return "CalendarViewController"
    }
    
    // MARK: Button handler
    @IBAction func settingHandler(_ sender: NSButton) {
        //NSApp.terminate(self)
        let menu = SettingMenu()
        SettingMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: sender)

    }
    @IBAction func lastMonthHandler(_ sender: NSButton) {
        var lastMonth = mCurMonth - 1
        if lastMonth < 1 {
            lastMonth = 12
            mCurYear -= 1
        }
        setDate(year: mCurYear, month: lastMonth)
    }
    
    @IBAction func nextMonthHandler(_ sender: NSButton) {
        var nextMonth = mCurMonth + 1
        if nextMonth > 12 {
            nextMonth = 1
            mCurYear += 1
        }
        setDate(year: mCurYear, month: nextMonth)
    }

    @IBAction func nextYearHandler(_ sender: NSButton) {
        let nextYear = mCurYear + 1
        setDate(year: nextYear, month: mCurMonth)
    }
    
    @IBAction func lastYearHandler(_ sender: NSButton) {
        let lastYear = mCurYear - 1
        setDate(year: lastYear, month: mCurMonth)
    }
    
    @IBAction func returnToday(_ sender: NSButton) {
        showToday()
    }
    // 响应NSTextField的回车事件
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if 	commandSelector == #selector(insertNewline(_:)) {
            
            let inputStr = textView.string
            
            let filterStr = inputStr.trimmingCharacters(in: .decimalDigits)
            if filterStr.count > 0 {
                // TODO: 提示
                // 包含非数字
                return false
            }
            
            // identifier 已定义在xib中
            if control.identifier!.rawValue == "monthField" {
                //print("month = \(inputStr)")
                let monthNum = Int(inputStr)!
                if monthNum < 1 || monthNum > 12 {
                    // TODO: 提示
                    return false
                }
                setDate(year: mCurYear, month: monthNum)
                
            } else if control.identifier!.rawValue == "yearField" {
                //print("year = \(textView.string!)")
                let yearNum = Int(inputStr)!
                
                if yearNum < CalendarConstant.GREGORIAN_CALENDAR_OPEN_YEAR || yearNum > 10000 {
                    // TODO: 提示
                    return false
                }
                setDate(year: yearNum, month: mCurMonth)
            }
            
            return true
        }
        
        return false
    }
    
    func getLunarDayName(dayInfo: DAY_INFO, cal: LunarCalendarUtils) -> String {
        var lunarDayName = ""

        if dayInfo.st != -1 {
            lunarDayName = CalendarConstant.nameOfJieQi[dayInfo.st]
        } else if dayInfo.mdayNo == 0 {
            let chnMonthInfo = cal.getChnMonthInfo(month: dayInfo.mmonth)
            if chnMonthInfo.isLeapMonth() {
                lunarDayName += CalendarConstant.LEAP_YEAR_PREFIX
            }
            
            lunarDayName += CalendarConstant.nameOfChnMonth[chnMonthInfo.mInfo.mname - 1]
            lunarDayName += (chnMonthInfo.mInfo.mdays == CalendarConstant.CHINESE_L_MONTH_DAYS) ? CalendarConstant.MONTH_NAME_1 : CalendarConstant.MONTH_NAME_2
        } else {
            lunarDayName += CalendarConstant.nameOfChnDay[dayInfo.mdayNo]
        }
        
        return lunarDayName
    }
    
    
    func showMonthPanel() {
        
        let year = mCurYear
        let month = mCurMonth
        
        let utils = CalendarUtils.sharedInstance
        
        let mi = mCalendar.getMonthInfo(month: mCurMonth)
        
        // 根据日期字符串获取当前月共有多少天
        let monthDays = mi.mInfo.days
        
        // 显示上方二个区域的年份与月份信息
        yearText.stringValue = String(mCurYear)
        monthText.stringValue = String(mCurMonth)
        // 上个月有多少天
        var lastMonthDays = 0
        if month == 1 {
            lastMonthDays = utils.getDaysBy(year: year - 1, month: 12)
        } else {
            lastMonthDays = utils.getDaysBy(year: year, month: month - 1)
        }
        
        
        // 本月第一天与最后一天是周几
        let weekDayOf1stDay = mi.mInfo.weekOf1stDay
        
        //print("dateString = \(year)-\(month) weekOf1stDay = \(weekDayOf1stDay) weekOfLastDay = \(weekDayOfLastDay) monthDays = \(monthDays) ")
        
        // 读取本地存储的颜色
        var festivalColor = NSColor.black
        if let data = UserDefaults.standard.value(forKey: SettingWindowController.FESTIVAL_COLOR_TAG) {
            festivalColor = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! NSColor
        }
        // 读取本地记录的颜色信息
        var holidayColor = NSColor.red
        if let data = UserDefaults.standard.value(forKey: SettingWindowController.HOLIDAY_COLOR_TAG) {
            holidayColor = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! NSColor
        }
        
        // 把空余不的cell行不显示，非本月天置灰
        for (index, btn) in cellBtns.enumerated() {
            btn.setBackGroundColor(bgColor: .white)
            btn.isEnabled = true
            btn.isHidden = false
            
            if index < weekDayOf1stDay || index >= monthDays + weekDayOf1stDay {
                // 前后二个月置灰，不可点击
                btn.isEnabled = false
                
                // 处理前后二个月的显示日期 (灰置部分)
                if index < weekDayOf1stDay {
                    
                    let day = lastMonthDays - weekDayOf1stDay + index + 1
                    var lastMonth = mCurMonth - 1
                    var calendar = mCalendar
                    if lastMonth < 1 {
                        lastMonth = 12
                        calendar = mPreCalendar
                    }

                    let (dayName, isFestival) = getMaxPriorityHolidayBy(month: lastMonth, day: day, cal: calendar)
                    var color = NSColor.black
                    if isFestival {
                        color = festivalColor
                    }
                    
                    btn.setString(wzTime: CalendarUtils.WZDayTime(calendar.getCurrentYear(), lastMonth, day), topColor: NSColor.black.withAlphaComponent(0.5), bottomText: dayName, bottomColor: color.withAlphaComponent(0.5))
                } else {
                    let day = index - monthDays - weekDayOf1stDay + 1
                    
                    var nextMonth = mCurMonth + 1
                    var calendar = mCalendar
                    if nextMonth > 12 {
                        nextMonth = 1
                        calendar = mNextCalendar
                    }
                    let (dayName, isFestival) = getMaxPriorityHolidayBy(month: nextMonth, day: day, cal: calendar)
                    var color = NSColor.black
                    if isFestival {
                        color = festivalColor
                    }
                    
                    btn.setString(wzTime: CalendarUtils.WZDayTime(calendar.getCurrentYear(), nextMonth, day), topColor: NSColor.black.withAlphaComponent(0.5), bottomText: dayName, bottomColor: color.withAlphaComponent(0.5))
                }
                
            } else {
                if index == monthDays + weekDayOf1stDay - 1 {
                    // 当前cell在第几行
                    lastRowNum = Int((btn.mCellID - 1) / 7) + 1
                }
                
                let day = index - weekDayOf1stDay + 1
                //btn.title = "\(index - weekDayOf1stDay + 1)"
                

                let (dayName, isFestival) = getMaxPriorityHolidayBy(month: mCurMonth, day: day, cal: mCalendar)
                
                let today = utils.getYMDTuppleBy(utils.getDateStringOfToday())
                if today.day == day && today.month == mCurMonth && today.year == mCurYear {
                    btn.setBackGroundColor(bgColor: CalendarConstant.selectedDateColor)
                    lastPressBtn = btn
                }
                var color = NSColor.black
                if isFestival {
                    color = festivalColor
                }
                btn.setString(wzTime: CalendarUtils.WZDayTime(mCurYear, mCurMonth, day), topColor: .black, bottomText: dayName, bottomColor: color)
                
                // 处理周六日的日期颜色
                if index % 7 == 6 || index % 7 == 0 {
   
                    if isFestival {
                        btn.setString(wzTime: CalendarUtils.WZDayTime(mCurYear, mCurMonth, day), topColor: holidayColor, bottomText: dayName, bottomColor: color)
                    } else {
                        btn.setString(wzTime: CalendarUtils.WZDayTime(mCurYear, mCurMonth, day), topColor: holidayColor, bottomText: dayName, bottomColor: holidayColor)
                    }
                }
            }
            
        }

    }
    

    
    
    // 根据xib中的identifier获取对应的cell
    func getButtonByIdentifier(_ id:String) -> NSView? {
        for subView in (self.window?.contentView?.subviews[0].subviews)! {
            if subView.identifier!.rawValue == id {
                return subView
            }
        }
        return nil
    }
    
    
    @objc func dateButtonHandler(_ sender:CalendarCellView){
        
        // 245	173	108 浅绿色
        if let tmp = lastPressBtn {
            tmp.setBackGroundColor(bgColor: .white)
        }
        sender.setBackGroundColor(bgColor: CalendarConstant.selectedDateColor)
        lastPressBtn = sender
        
        mCurDay = sender.wzDay.day
        showRightDetailInfo(wzTime: sender.wzDay)
    }
    
    func showHolidayCountDown(wzTime: CalendarUtils.WZDayTime){
        let (holidayName, days) = CalendarUtils.sharedInstance.getNextHolidayBy(wzTime: wzTime)
        nextHolidayTip.stringValue = "距离\(holidayName)"
        nextHolidayDays.stringValue = "\(days)"
    }
    
    // 显示日历面板右侧详情
    func showRightDetailInfo(wzTime: CalendarUtils.WZDayTime) {
        // 获取每月第一天是周几
        let curWeekDay = CalendarUtils.sharedInstance.getWeekDayBy(mCurYear, month: mCurMonth, day: mCurDay)
        dateDetailLabel.stringValue = String(mCurDay) + "/" + String(mCurMonth) + "/" + String(mCurYear) + " " + CalendarConstant.WEEK_NAME_OF_CHINESE[curWeekDay]
        dayLabel.stringValue = String(mCurDay)
        
        // 右侧农历详情
        showLunar()
        // 显示假日信息
        showHolidayInfo()
        // 显示倒日
        showHolidayCountDown(wzTime: wzTime)
        // 当前日期如果有备注显示备注信息
        let info = LocalDataManager.sharedInstance.getCurDateFlag(wzDay: wzTime)
        showPinNote(info: info)
    }
    
    // 显示便签
    func showPinNote(info: String) {
        pinNote.isHidden = true
        if info != "" {
            pinNote.isHidden = false
            pinNote.stringValue = info
            
        }
    }
    
    func showLunar() {
        var stems: Int = 0, branches: Int = 0, sbMonth:Int = 0, sbDay:Int = 0
        let year = mCalendar.getCurrentYear()
        mCalendar.getSpringBeginDay(month: &sbMonth, day: &sbDay)
        let util = CalendarUtils.sharedInstance
        var y = year
        if mCurMonth < sbMonth {
            y = year - 1
        } else {
            if mCurMonth == sbMonth && mCurDay < sbDay {
                y = year - 1
            }
        }
        util.calculateStemsBranches(year: y, stems: &stems, branches: &branches)
        branches -= 1
        
        let monthHeavenEarthy = util.getLunarMonthNameBy(calendar: mCalendar, month: mCurMonth, day: mCurDay)
        let dayHeavenEarthy = util.getLunarDayNameBy(year: mCurYear, month: mCurMonth, day: mCurDay)
        
        // 当前的农历年份
        let lunarStr = "\(CalendarConstant.HEAVENLY_STEMS_NAME[stems - 1])\(CalendarConstant.EARTHY_BRANCHES_NAME[branches])【\(CalendarConstant.CHINESE_ZODIC_NAME[branches])】年"
        lunarYearLabel.stringValue = lunarStr + monthHeavenEarthy.heaven + monthHeavenEarthy.earthy + "月" + dayHeavenEarthy.heaven + dayHeavenEarthy.earthy + "日"
        
        imageView.image = NSImage(named: CalendarConstant.CHINESE_ZODIC_PNG_NAME[branches])
//        poemLabel.stringValue = CalendarConstant.LAST_POEM[branches - 1]
//        nextPoemLabel.stringValue = CalendarConstant.NEXT_POEM[branches - 1]
        
        // 当前的农历日期
        let mi = mCalendar.getMonthInfo(month: mCurMonth)
        let dayInfo = mi.getDayInfo(day: mCurDay)
        let chnMonthInfo = mCalendar.getChnMonthInfo(month: dayInfo.mmonth)
        
        var lunarDayName = CalendarConstant.nameOfChnMonth[chnMonthInfo.mInfo.mname - 1] + "月"
        if chnMonthInfo.isLeapMonth() {
            lunarDayName = CalendarConstant.LEAP_YEAR_PREFIX + lunarDayName
        }

        let dayName = CalendarConstant.nameOfChnDay[dayInfo.mdayNo]

        lunarDateLabel.stringValue = lunarDayName + dayName
    }
    
    // 显示节日信息
    func showHolidayInfo(){
        let holidayName = CalendarUtils.sharedInstance.getHolidayNameBy(month: mCurMonth, day: mCurDay)
        holidayLabel.stringValue = holidayName
        
        //农历节日
        let mi = mCalendar.getMonthInfo(month: mCurMonth)
        let dayInfo = mi.getDayInfo(day: mCurDay)
        let chnMonthInfo = mCalendar.getChnMonthInfo(month: dayInfo.mmonth)
        
        let festivalName = CalendarUtils.sharedInstance.getLunarFestivalNameBy(month: chnMonthInfo.mInfo.mname, day: dayInfo.mdayNo + 1)
        
        var jieQiName = ""
        if dayInfo.st != -1 {
            jieQiName = CalendarConstant.nameOfJieQi[dayInfo.st]
        }
        
        holidayLabel.stringValue = jieQiName + " " + festivalName + " " + holidayName
    }
    
    // 获取当前日期的节日信息并返回优先在cell中显示的节日信息
    func getMaxPriorityHolidayBy(month: Int, day: Int, cal: LunarCalendarUtils) -> (String, Bool){
        var maxPriorityHolidayName = ""
        var isFestvial = false
        // 依次是 农历日期/节气，公历节日，农历节日
        let mi = cal.getMonthInfo(month: month)
        let dayInfo = mi.getDayInfo(day: day)
        let chnMonthInfo = cal.getChnMonthInfo(month: dayInfo.mmonth)
        
        // 农历日期/节气
        maxPriorityHolidayName = CalendarConstant.nameOfChnDay[dayInfo.mdayNo]
        if dayInfo.st != -1 {
            isFestvial = true
        }
        
        // 公历节日
        let holidayName = CalendarUtils.sharedInstance.getHolidayNameBy(month: month, day: day)
        if holidayName != "" && holidayName.count <= 4 {
//            maxPriorityHolidayName = holidayName
            isFestvial = true
        }
        
        // 农历节日
        let festivalName = CalendarUtils.sharedInstance.getLunarFestivalNameBy(month: chnMonthInfo.mInfo.mname, day: dayInfo.mdayNo + 1)
        if festivalName != "" {
//            maxPriorityHolidayName = festivalName
            isFestvial = true
        }
        
        if dayInfo.mdayNo == 0 {
            maxPriorityHolidayName += "/\(mi.mInfo.month)"
        }
        
        return (maxPriorityHolidayName, isFestvial)
    }
    
    
    
    func setCurrenMonth(month: Int) {
        if month >= 1 && month <= CalendarConstant.MONTHES_FOR_YEAR {
            mCurMonth = month
            showMonthPanel()
        }
    }
    
    func setDate(year: Int, month: Int) {
        mCurYear = year
        let _ = mPreCalendar.setGeriYear(year: mCurYear - 1)
        let _ = mNextCalendar.setGeriYear(year: mCurYear + 1)
        if mCalendar.setGeriYear(year: year) {
            setCurrenMonth(month: month)
        }

    }
    
    // 显示今天
    func showToday() {
        let date = CalendarUtils.sharedInstance.getDateStringOfToday()
        let dateTupple = CalendarUtils.sharedInstance.getYMDTuppleBy(date)
        mCurDay = dateTupple.day
        mCurYear = dateTupple.year
        let _ = mPreCalendar.setGeriYear(year: mCurYear - 1)
        let _ = mNextCalendar.setGeriYear(year: mCurYear + 1)
        if mCalendar.setGeriYear(year: mCurYear) {
            setCurrenMonth(month: dateTupple.month)
            showRightDetailInfo(wzTime: CalendarUtils.WZDayTime(mCurYear, mCurMonth, mCurDay))
        }
    }
    
    // 设置周六周日字的颜色
    func setWeekendLabelColor() {
        // 读取本地记录的颜色信息
        var color = NSColor.red
        if let data = UserDefaults.standard.value(forKey: SettingWindowController.HOLIDAY_COLOR_TAG) {
            color = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! NSColor
        }
        saturdayLabel.textColor = color
        sundayLabel.textColor = color
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        LocalDataManager.sharedInstance.parseHoliday()
        
        pinNote.layer?.cornerRadius = 5.5
        pinNote.layer?.masksToBounds = true
        // 背景透明，使用view设置圆角矩形
        self.window?.backgroundColor = NSColor.clear
        //self.blur(view: self.backView)
        
        // 将所有cell加入数组管理，并加入回调逻辑
        for i in 0 ... 5 {
            for j in 0 ... 6 {
                let intValue = (i * 7 + j + 1)
                let id = "cell\(intValue)"
                if let btn = self.getButtonByIdentifier(id) {
                    let cellBtn = btn as! CalendarCellView
                    cellBtn.target = self
                    cellBtn.action = #selector(CalendarViewController.dateButtonHandler(_:))
                    cellBtn.mCellID = intValue
                    cellBtns.append(cellBtn)
                }
            }
        }
        
        // 加载完窗口显示默认
        showToday()
        setWeekendLabelColor()
    }
    
}
