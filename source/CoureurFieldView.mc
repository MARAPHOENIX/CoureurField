using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;
using Toybox.Position as Pos;


//! @author Konrad Paumann
class CoureurField extends App.AppBase {

    function getInitialView() {
        var view = new CoureurView();
        return [ view ];
    }
}

//! A DataField that shows some infos.
//!
//! @author Konrad Paumann
class CoureurView extends Ui.DataField {

   hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const HEADER_FONT = Graphics.FONT_XTINY;
    hidden const VALUE_FONT = Graphics.FONT_NUMBER_MEDIUM;
    hidden const ZERO_TIME = "-:--";
    hidden const ZERO_DISTANCE = "-.--";
    
    hidden var kmOrMileInMeters = 1000;
    hidden var is24Hour = true;
    hidden var distanceUnits = System.UNIT_METRIC;
    hidden var textColor = Graphics.COLOR_BLACK;
    hidden var inverseTextColor = Graphics.COLOR_WHITE;
    hidden var backgroundColor = Graphics.COLOR_WHITE;
    hidden var inverseBackgroundColor = Graphics.COLOR_BLACK;
    hidden var inactiveGpsBackground = Graphics.COLOR_LT_GRAY;
    hidden var batteryBackground = Graphics.COLOR_WHITE;
    hidden var batteryColor1 = Graphics.COLOR_GREEN;
    hidden var hrColor = Graphics.COLOR_RED;
    hidden var lapColor = Graphics.COLOR_DK_BLUE;
    hidden var headerColor = Graphics.COLOR_DK_GRAY;
        
    
    hidden var paceData = new DataQueue(10);
    hidden var paceData30 = new DataQueue(30);
    hidden var paceData3 = new DataQueue(3);


    hidden var doUpdates = 0;

    hidden var avgSpeed= 0;
    hidden var hr = 0;
    hidden var distance = 0;
    hidden var elapsedTime = 0;
    hidden var gpsSignal = 0;
    
    hidden var currentCadence = 0;
    hidden var averageCadence = 0;
    hidden var maxCadence = 0;
    
    
     //lap
    hidden var compteurLap = 0;
    hidden var compteurLapAff=0;
    hidden var distLap=0;
    hidden var distLapStr;
    hidden var durationLap;
    hidden var timeLap=0;
    hidden var timeLapTmp=0;
    hidden var distLapCourant=0;
    hidden var timeLapCourant=0;
    hidden var speedCourant=0;
    hidden var speedLap = 0;
    hidden var speedLapKMH = 0;
    hidden var changeScreen = 0;
    hidden var lapSup1=0;
    
    hidden var ascension=0;
    
    hidden var computeAvgSpeed;
    hidden var computeAvgSpeed3s;
    hidden var computeAvgSpeed30s;
    hidden var vMoy;
    
    
    hidden var hasBackgroundColorOption = false;
    hidden var type = "";
    
    function initialize() {
        DataField.initialize();
    }
    
    function onTimerLap(){
        lapSup1 = 1;
        compteurLap = compteurLap + 1;
        compteurLapAff = compteurLapAff + compteurLap%2;
		
		if (compteurLap%2 == 0){
			type="Repos";
		}else{
			type="";
		}
     	
        
        distLapCourant = distance != null ? distance : 0;
        timeLapTmp = elapsedTime - timeLapCourant; 
        timeLapCourant = elapsedTime != null ? elapsedTime : 0;
                
        if (timeLapTmp<4000){
        	if (changeScreen == 0){
        		changeScreen = 1;
        		compteurLap=0;
        		compteurLapAff=0;
        	}else {
        	    changeScreen = 0;
        	}
        }else if (timeLapTmp<10000){
        	compteurLap=0;
        	compteurLapAff=0;
        }
    }

    //! The given info object contains all the current workout
    function compute(info) {
        if (info.currentSpeed != null) {
            paceData.add(info.currentSpeed);
            paceData30.add(info.currentSpeed);
            paceData3.add(info.currentSpeed);
        } else {
            paceData.reset();
            paceData30.reset();
            paceData3.reset;      
        }
        
        avgSpeed = info.averageSpeed != null ? info.averageSpeed : 0;
        elapsedTime = info.timerTime != null ? info.timerTime : 0;        
        hr = info.currentHeartRate != null ? info.currentHeartRate : 0;
        distance = info.elapsedDistance != null ? info.elapsedDistance : 0;
        gpsSignal = info.currentLocationAccuracy != null ? info.currentLocationAccuracy : 0;
        ascension = info.totalAscent != null ? info.totalAscent : 0;


        maxCadence = info.maxCadence != null ? info.maxCadence : 0;
        averageCadence = info.averageCadence != null ? info.averageCadence : 0;
        currentCadence = info.currentCadence != null ? info.currentCadence : 0;
    
        if (compteurLap == 0 && lapSup1 == 0){
            speedLap = avgSpeed;
            distLap=distance;
            timeLap=elapsedTime;
        }else{
            if (elapsedTime != null &&  distance != null){
                distLap = distance - distLapCourant;
                timeLap =  elapsedTime - timeLapCourant;
                if (distLap>0 && timeLap>0){
                    var timeLapSecond = timeLap / 1000;
                    if (timeLapSecond != null && timeLapSecond > 0.2){
                        speedLap = distLap / timeLapSecond;
                    }else{
                        speedLap = 0;
                    }
                   
                }else{
                    speedLap = 0;
                }
            }
        }
        
        if (hr>170){
        	hrColor = Graphics.COLOR_RED;
    	}else if (hr<140){
    		hrColor = Graphics.COLOR_DK_GREEN;
    	}else{
    		hrColor = Graphics.COLOR_DK_BLUE;
    	}
    }
    
    function onLayout(dc) {
        setDeviceSettingsDependentVariables();
        //onUpdate(dc);
    }
    
    function onShow() {
        doUpdates = true;
        return true;
    }
    
    function onHide() {
        doUpdates = false;
    }
    
    function onUpdate(dc) {
        if(doUpdates == false) {
            return;
        }
        
        setColors();
        // reset background
        dc.setColor(backgroundColor, backgroundColor);
        dc.fillRectangle(0, 0, 218, 218);
        
        drawValues(dc);
    }

    function setDeviceSettingsDependentVariables() {
        hasBackgroundColorOption = (self has :getBackgroundColor);
        
        distanceUnits = System.getDeviceSettings().distanceUnits;
        if (distanceUnits == System.UNIT_METRIC) {
            kmOrMileInMeters = 1000;
        } else {
            kmOrMileInMeters = 1610;
        }
        is24Hour = System.getDeviceSettings().is24Hour;
        
      
    }
    
    function setColors() {
        if (hasBackgroundColorOption) {
            backgroundColor = getBackgroundColor();
            //TODO:pour les tests
            //backgroundColor = Graphics.COLOR_BLACK;
            textColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            inverseTextColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            inverseBackgroundColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            hrColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_BLUE;
            headerColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_LT_GRAY: Graphics.COLOR_DK_GRAY;
            batteryColor1 = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GREEN;
            lapColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_BLUE;
        }
    }
    

        
    function drawValues(dc) {
    
        //time
        var clockTime = System.getClockTime();
        var time, ampm;
        if (is24Hour) {
            time = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%.2d")]);
            ampm = "";
        } else {
            time = Lang.format("$1$:$2$", [computeHour(clockTime.hour), clockTime.min.format("%.2d")]);
            ampm = (clockTime.hour < 12) ? "am" : "pm";
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0,0,218,20);
        dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(106, 10, Graphics.FONT_TINY, time, CENTER);
        var battery = System.getSystemStats().battery;
        dc.drawText(142, 11, HEADER_FONT,battery.format("%d"), CENTER);
        
        dc.setColor(inverseBackgroundColor,  Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 157, 218, 218);
        
        //pace
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(dc.getWidth()/2, 57, Graphics.FONT_NUMBER_THAI_HOT, getMinutesPerKmOrMile(computeAverageSpeed()), CENTER);
        
        var computeAvgSpeed = computeAverageSpeed(paceData);
        var computeAvgSpeed3s = computeAverageSpeed(paceData3);
        var computeAvgSpeed30s = computeAverageSpeed(paceData30);
        
        if (computeAvgSpeed<1.67){
        //if (computeAvgSpeed>0){
          dc.drawText(dc.getWidth()/2-3, 68, Graphics.FONT_NUMBER_HOT, getMinutesPerKmOrMile(computeAvgSpeed), CENTER);//getMinutesPerKmOrMile(computeAvgSpeed)
        }else {
          dc.drawText(dc.getWidth()/2-3, 57, Graphics.FONT_NUMBER_THAI_HOT, getMinutesPerKmOrMile(computeAvgSpeed), CENTER);
        }
        
        //hr
        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        if (hr>0){
         dc.drawText(30, 50, HEADER_FONT, "HR", CENTER); 
         dc.drawText(30, 76, VALUE_FONT, hr.format("%d"), CENTER);//hr.format("%d")
        }
        else{
         dc.drawText(30, 50, HEADER_FONT, "D+", CENTER); 
         
         //ascension = 655;
         if (ascension < 1000){
            dc.drawText(30, 76,VALUE_FONT,ascension.format("%d"), CENTER);//ascension.format("%d")
         }else{
            dc.drawText(30, 76,Graphics.FONT_NUMBER_MILD,ascension.format("%d"), CENTER);//ascension.format("%d")
         }
       	} 
        
        //cadence
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()-35, 76, VALUE_FONT, currentCadence.format("%d"), CENTER);//currentCadence.format("%d")

        //apace
        dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
        if (changeScreen == 0){
        	vMoy = avgSpeed;
            dc.drawText(110, 180, Graphics.FONT_NUMBER_HOT, getMinutesPerKmOrMile(avgSpeed), CENTER);
        }else{
            vMoy = speedLap;
            dc.drawText(110, 180, Graphics.FONT_NUMBER_HOT, getMinutesPerKmOrMile(speedLap), CENTER);
        }
                
        //distance
        var distStr;
       	var distEtude = distance;
       	if (changeScreen == 1){
       		distEtude = distLap;
       	} 
        
        if (distEtude > 0) {
            var distanceKmOrMiles = distEtude / kmOrMileInMeters;
            if (distanceKmOrMiles < 100) {
                distStr = distanceKmOrMiles.format("%.2f");
            } else {
                distStr = distanceKmOrMiles.format("%.1f");
            }
        } else {
            distStr = ZERO_DISTANCE;
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(50 , 131, VALUE_FONT, distStr, CENTER);
                
        //duration
        var duration;
        var timeEtude = elapsedTime;
        if (changeScreen == 1){
       		timeEtude = timeLap;
       	} 
        if (timeEtude != null && timeEtude > 0) {
            var hours = null;
            var minutes = timeEtude / 1000 / 60;
            var seconds = timeEtude / 1000 % 60;
            
            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
            }
            
            if (hours == null) {
                duration = minutes.format("%d") + ":" + seconds.format("%02d");
            } else {
                duration = hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
            }
        } else {
            duration = ZERO_TIME;
        } 
        if (changeScreen==1){
            dc.drawText(175, 131, VALUE_FONT, duration, CENTER);
        }else{
            dc.drawText(150, 131, VALUE_FONT, duration, CENTER);
       	}
     
        
        // headers:
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(105, 10, HEADER_FONT, paceStr, CENTER);
        if (changeScreen == 0){
           //dc.drawText(165, 168, HEADER_FONT, "avg", CENTER);
        }else{
           //dc.drawText(165, 185, HEADER_FONT, "lap", CENTER);
           dc.drawText(175, 185, HEADER_FONT, compteurLap.format("%d"), CENTER);
        }
        
        //dc.drawText(165, 182, HEADER_FONT, "pace", CENTER);
        dc.drawText(185, 50, HEADER_FONT, "CAD", CENTER); 
        
        dc.drawText(50, 106, HEADER_FONT, "DIST", CENTER);
        
        if (changeScreen==1){
            dc.drawText(175, 106, HEADER_FONT, "CHRONO", CENTER);
            dc.drawText(109, 106, HEADER_FONT, type, CENTER);
        }else{
            dc.drawText(150, 106, HEADER_FONT, "CHRONO", CENTER);
       	}

		
        
        //grid
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 100, dc.getWidth(), 100);
        dc.drawLine(0, 156, dc.getWidth(), 156);
        
        
        if (changeScreen==1){
          dc.drawLine(dc.getWidth()/2-20, 100, dc.getWidth()/2-20, 157);
          dc.drawLine(dc.getWidth()/2+20, 100, dc.getWidth()/2+20, 157);
          dc.setColor(lapColor, Graphics.COLOR_TRANSPARENT);
          dc.drawText(dc.getWidth()/2, 130, VALUE_FONT, compteurLapAff.format("%d"), CENTER);//compteurLapAff.format("%d")
        }
        
                
      
        if (computeAvgSpeed>=computeAvgSpeed3s){
        	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(0,157,62,28);
        }else if (computeAvgSpeed3s>computeAvgSpeed){
         	dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(0,157,62,28);
        }
     	
     	 if (vMoy>computeAvgSpeed30s){
        	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(154,157,62,28);
        }else if (computeAvgSpeed30s>=vMoy){
         	dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(154,157,62,28);
        }
        
          // gps 
        if (gpsSignal <= 2) {
           dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
           dc.drawText(50, 190, HEADER_FONT, "GPS", CENTER);        
        } 
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(43, 168, Graphics.FONT_NUMBER_MILD, getMinutesPerKmOrMile(computeAvgSpeed3s), CENTER);// getMinutesPerKmOrMile(computeAvgSpeed3s)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(174, 168, Graphics.FONT_NUMBER_MILD, getMinutesPerKmOrMile(computeAvgSpeed30s), CENTER);// getMinutesPerKmOrMile(computeAvgSpeed30s)
    }
    
   
    
   function computeAverageSpeed(tableau) {
        var size = 0;
        var data = tableau.getData();
        var sumOfData = 0.0;
        for (var i = 0; i < data.size(); i++) {
            if (data[i] != null) {
                sumOfData = sumOfData + data[i];
                size++;
            }
        }
        if (sumOfData > 0) {
            return sumOfData / size;
        }
        return 0.0;
    }
    
    function computeHour(hour) {
        if (hour < 1) {
            return hour + 12;
        }
        if (hour >  12) {
            return hour - 12;
        }
        return hour;      
    }
    
    //! convert to integer - round ceiling 
    function toNumberCeil(float) {
        var floor = float.toNumber();
        if (float - floor > 0) {
            return floor + 1;
        }
        return floor;
    }
    
    function getMinutesPerKmOrMile(speedMetersPerSecond) {
        if (speedMetersPerSecond != null && speedMetersPerSecond > 0.2) {
            var metersPerMinute = speedMetersPerSecond * 60.0;
            var minutesPerKmOrMilesDecimal = kmOrMileInMeters / metersPerMinute;
            var minutesPerKmOrMilesFloor = minutesPerKmOrMilesDecimal.toNumber();
            var seconds = (minutesPerKmOrMilesDecimal - minutesPerKmOrMilesFloor) * 60;
            return minutesPerKmOrMilesDecimal.format("%2d") + ":" + seconds.format("%02d");
        }
        return ZERO_TIME;
    }

}

//! A circular queue implementation.
//! @author Konrad Paumann
class DataQueue {

    //! the data array.
    hidden var data;
    hidden var maxSize = 0;
    hidden var pos = 0;

    //! precondition: size has to be >= 2
    function initialize(arraySize) {
        data = new[arraySize];
        maxSize = arraySize;
    }
    
    //! Add an element to the queue.
    function add(element) {
        data[pos] = element;
        pos = (pos + 1) % maxSize;
    }
    
    //! Reset the queue to its initial state.
    function reset() {
        for (var i = 0; i < data.size(); i++) {
            data[i] = null;
        }
        pos = 0;
    }
    
    //! Get the underlying data array.
    function getData() {
        return data;
    }
}