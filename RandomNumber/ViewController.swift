//
//  ViewController.swift
//  RandomNumber
//
//  Created by Rishu Agrawal on 30/07/17.
//  Copyright © 2017 Time Inc. All rights reserved.
//

import UIKit
import SocketIO
import CoreData
import Charts

class ViewController: UIViewController {
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    @IBOutlet weak var randomNumberLabel: UILabel!
    var date : NSDate?
    var dateFormatter : NSDateFormatter?
    var timer = NSTimer()
    
    var numbers: [NSManagedObject] = []
    let socket = SocketIOClient(socketURL: NSURL(string: "http://ios-test.us-east-1.elasticbeanstalk.com/")!, config: [.Log(true), .Nsp("/random")])
    let notification = UILocalNotification()
    var previousNumber = -1
    var randomNumber = 0
    var k=0
    
    var xAxisArray : [Int] = []
    var yAxisArray : [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureChart()
        self.randomNumberLabel.textAlignment = .Center
        randomNumberLabel.font = UIFont.boldSystemFontOfSize(14)
        socket.on("connect") {data, ack in
            print("socket connected")
        }
        
        socket.on("capture") {data, ack in
            if let cur = data[0] as? Double {
                self.socket.emitWithAck("canUpdate", cur)(timeoutAfter: 0) {data in
                    self.socket.emit("update", ["amount": cur + 2.50])
                }
                ack.with(true)
            }
            self.randomNumber = data[0] as! Int
            let time = NSDate()
            if self.randomNumber < 10 {
                self.randomNumberLabel.text = "Current Number [\(self.randomNumber)]"
                print("rand :", self.randomNumber, "\t\t\ttime :", time)
                self.saveData(self.randomNumber, time: time)
                self.previousNumber = self.randomNumber
                self.yAxisArray.append(self.randomNumber)
                
                if self.previousNumber == self.randomNumber {
                    self.sendLocalNotification(self.randomNumber, time: time)
                }
                
                let stringArray = NSMutableArray()
                let numberArray = NSMutableArray()
                
                self.dateFormatter = NSDateFormatter()
                self.dateFormatter!.dateFormat = "HH:mm:ss"
                self.date = NSDate()
                
                //Insert random values into chart
                stringArray.addObject(self.date!)
                numberArray.addObject(self.randomNumber)
                
                self.xAxisArray.append(self.k)
                self.k += 4
                self.configureChart()
                
                NSTimer.scheduledTimerWithTimeInterval(time.timeIntervalSinceNow + 0.2, target: self, selector: "setData", userInfo: nil, repeats: true)
                self.lineChartView.leftAxis.labelCount = 10
            }
        }
        socket.connect()
    }
    
    func configureChart() {
        lineChartView.descriptionText = "Random Number < 10"
        lineChartView.noDataTextDescription = "Add Data"
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.dragEnabled = true
        lineChartView.rightAxis.enabled = false
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.legend.enabled = false
        
        let chartXAxis = lineChartView.xAxis as ChartXAxis
        chartXAxis.labelPosition = .Bottom
        chartXAxis.setLabelsToSkip(2)
        lineChartView.zoom(1.0, scaleY: 1.0, x: 0.0, y: 0.0)
    }
    
    func getColor(isColorChangeRequired: Bool) -> UIColor {
        return isColorChangeRequired ? UIColor.redColor() : UIColor.blueColor().colorWithAlphaComponent(0.5)
    }
    
    func isColorChangeRequired() -> Bool {
        return randomNumber > 7 ? true : false
    }
    
    func setData() {
        var yVals1 : [ChartDataEntry] = [ChartDataEntry]()
        for var i = 0; i < xAxisArray.count; i++ {
            let val = self.yAxisArray[i]
            yVals1.append(ChartDataEntry(value: Double(val), xIndex: i))
        }
        
        let set1: LineChartDataSet = LineChartDataSet(yVals: yVals1, label: "")
        let colorChnageRequired = isColorChangeRequired()
        set1.axisDependency = .Left
        set1.setColor(UIColor.blueColor().colorWithAlphaComponent(0.5))
        set1.setCircleColor(getColor(colorChnageRequired))
        set1.lineWidth = 2.0
        set1.circleRadius = 6.0
        set1.fillAlpha = 65 / 255.0
        set1.fillColor = UIColor.blueColor()
        set1.highlightColor = UIColor.whiteColor()
        set1.drawCircleHoleEnabled = true
        set1.drawFilledEnabled = true
        
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(set1)
        
        let data: LineChartData = LineChartData(xVals: xAxisArray, dataSets: dataSets)
        self.lineChartView.data = data
        
        lineChartView.data?.setValueTextColor(UIColor.clearColor())
        self.lineChartView.notifyDataSetChanged()
        self.lineChartView.moveViewToX(CGFloat(k))
    }
    
    var i = 0,j=0
    func updateCounter(randomNumber: Int) {
        self.lineChartView.data?.addEntry(ChartDataEntry(value: Double(yAxisArray[j]), xIndex: i), dataSetIndex: 0)
        self.lineChartView.data?.addXValue(String(i))
        self.lineChartView.leftAxis.labelCount = 10
        self.lineChartView.setVisibleXRange(minXRange: CGFloat(-10), maxXRange: CGFloat(200))
        self.lineChartView.notifyDataSetChanged()
        self.lineChartView.moveViewToX(CGFloat(j))
        i = i + 4
        j = j+1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func saveData(number: Int, time: NSDate) {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("RandomNumber", inManagedObjectContext: managedContext)
        
        let newRandomNumber = NSManagedObject(entity: entityDescription!, insertIntoManagedObjectContext: managedContext)
        newRandomNumber.setValue(number, forKey: "number")
        newRandomNumber.setValue(time, forKey: "createdAt")
        do {
            try newRandomNumber.managedObjectContext?.save()
        } catch {
            print("error is:", error)
        }
    }
    
    func fetchData() {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("RandomNumber", inManagedObjectContext: appDelegate.managedObjectContext)
        fetchRequest.entity = entityDescription
        do {
            let result = try appDelegate.managedObjectContext.executeFetchRequest(fetchRequest)
            print("result is : ",result)
        } catch {
            let fetchError = error as NSError
            print("fetch error: ", fetchError)
        }
    }
    
    func sendLocalNotification(number: Int, time: NSDate) {
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
        notification.alertBody = "\(number) has appeared consecutively."
        notification.alertAction = "open"
        notification.userInfo = ["title": "CONSECUTIVE"]
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
}

