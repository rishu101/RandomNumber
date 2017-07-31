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
    var yAxisArray: [Int] = []
    
    var date : NSDate?
    var dateFormatter : NSDateFormatter?
    var timer = NSTimer()
    
    var numbers: [NSManagedObject] = []
    let socket = SocketIOClient(socketURL: NSURL(string: "http://ios-test.us-east-1.elasticbeanstalk.com/")!, config: [.Log(true), .Nsp("/random")])
    let notification = UILocalNotification()
    var previousNumber = -1
    var randomNumber = 8

    override func viewDidLoad() {
        super.viewDidLoad()
        configureChart()
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
                print("rand :", self.randomNumber, "\t\t\ttime :", time)
                self.saveData(self.randomNumber, time: time)
                self.previousNumber = self.randomNumber
                self.yAxisArray.append(self.randomNumber)
                
                var set_a = LineChartDataSet()
                set_a = LineChartDataSet(yVals: [ChartDataEntry](), label: "a")
                set_a.drawCirclesEnabled = false
                set_a.lineWidth = 2
                set_a.axisDependency = .Left
                set_a.setColor(UIColor.blueColor())
                
                self.lineChartView.data = LineChartData(xVals: ["0", "4", "8", "12", "16"], dataSets: [set_a])
                
//                self.timer = NSTimer.scheduledTimerWithTimeInterval(4, target:self, selector: "updateCounter", userInfo: nil, repeats: true)
                self.updateCounter(self.randomNumber)
            }
            if self.previousNumber == self.randomNumber {
                self.sendLocalNotification(self.randomNumber, time: time)
            }
        }
        socket.connect()
        
    }
    
    func setData()
    {
        // 1 - creating an array of data entries
        var yVals1 : [ChartDataEntry] = [ChartDataEntry]()
        //        for var i = 0; i < xAxisArray.count; i++ {
        //            yVals1.append(ChartDataEntry(value: yAxisArray[i], xIndex: i))
        //        }
        
        // 2 - create a data set with our array
        let set1: LineChartDataSet = LineChartDataSet(yVals: yVals1, label: "")
        
        set1.axisDependency = .Left // Line will correlate with left axis values
        set1.setColor(UIColor.blueColor().colorWithAlphaComponent(0.5)) // our line's opacity is 50%
        set1.setCircleColor(UIColor.blueColor()) // our circle will be dark red
        set1.lineWidth = 2.0
        set1.circleRadius = 6.0 // the radius of the node circle
        set1.fillAlpha = 65 / 255.0
        set1.fillColor = UIColor.blueColor()
        set1.highlightColor = UIColor.whiteColor()
        set1.drawCircleHoleEnabled = true
        set1.drawFilledEnabled = true
        
        //3 - create an array to store our LineChartDataSets
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(set1)
        
        //4 - pass our months in for our x-axis label value along with our dataSets
        let data: LineChartData = LineChartData(xVals: yAxisArray, dataSets: dataSets)
        
        //5 - finally set our data
        self.lineChartView.data = data
        
        //Clear text color
        lineChartView.data?.setValueTextColor(UIColor.clearColor())
    }
    
    var i = 0,j=0
    func updateCounter(randomNumber: Int) {
        self.lineChartView.data?.addEntry(ChartDataEntry(value: Double(yAxisArray[j]), xIndex: i), dataSetIndex: 0)
        self.lineChartView.data?.addXValue(String(i))
        self.lineChartView.leftAxis.labelCount = 10
        self.lineChartView.setVisibleXRange(minXRange: CGFloat(-10), maxXRange: CGFloat(200))
        self.lineChartView.notifyDataSetChanged()
//        self.lineChartView.moveViewToX(CGFloat(j))
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
        print("Time is :", time)
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
//            let num = result[0] as! NSManagedObject
//            appDelegate.managedObjectContext.deleteObject(num)
            print("result is : ",result)
        } catch {
            let fetchError = error as NSError
            print("fetch error: ", fetchError)
        }
//        do {
//            try appDelegate.managedObjectContext.save()
//        } catch {
//            print("deleting error :",error)
//        }
    }
    
    func sendLocalNotification(number: Int, time: NSDate) {
        let notification = UILocalNotification()
//        notification.fireDate = time.dateByAddingTimeInterval(5)
        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
        notification.alertBody = "\(number) has appeared consecutively."
        notification.alertAction = "open"
        notification.userInfo = ["title": "CONSECUTIVE"]
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func setChart(xAxis: [Int], yAxis: [Int]) {
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<xAxis.count {
            let dataEntry = ChartDataEntry(value: Double(xAxis[i]), xIndex: i)
            dataEntries.append(dataEntry)
        }
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "Units Sold")
        let lineChartData = LineChartData(xVals: xAxis, dataSet: lineChartDataSet)
        lineChartView.data = lineChartData
    }
    
    func configureChart()
    {
        //Chart config
        lineChartView.descriptionText = "TEST"
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.dragEnabled = true
        lineChartView.rightAxis.enabled = false
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.legend.enabled = false
        
        //Configure xAxis
        let chartXAxis = lineChartView.xAxis as ChartXAxis
        chartXAxis.labelPosition = .Bottom
        chartXAxis.setLabelsToSkip(5)
        
        //configure yAxis
        lineChartView.zoom(1.0, scaleY: 1.0, x: 0.0, y: 0.0)
    }
    
}

