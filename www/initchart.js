// Initialiation for dynamic Highchart

$(document).ready(function() {
  Highcharts.setOptions({
    global: {
      useUTC: true
    }
  });

  // Generate an array of blank data
  var blankdata = function() {
    var data = [],
        time = (new Date()).getTime(),
        i;

    for (i = -20; i <= -1; i++) {
      data.push({
        x: time + i * 3000,
        y: 100
      });
    }
    return data;
  };

  $("#live_highchart").highcharts({
    chart: {
      type: "line",
      animation: Highcharts.svg, // dont animate in old IE
      marginRight: 10
    },
    title: {
      text: "Recent values"
    },
    xAxis: {
      type: "datetime",
      tickPixelInterval: 150
    },
    yAxis: {
      title: {
        text: "Value"
      },
      min: 0,
      // max: 100,
      plotLines: [{
        value: 0,
        width: 1,
        color: "#808080"
      }]
    },
    tooltip: {
      formatter: function() {
          return "<b>"+ this.series.name +"</b><br/>"+
          Highcharts.dateFormat("%Y-%m-%d %H:%M:%S", this.x) +"<br/>"+
          Highcharts.numberFormat(this.y, 2);
      }
    },
    legend: {
      enabled: false
    },
    series: [{
      name: "Random data",
      data: blankdata()
    },
    {
      name: "Running average of last 10",
      data: blankdata()
    }]
  });


  // Handle messages from server - update graph
  Shiny.addCustomMessageHandler("updateHighchart",
    function(message) {
      // Find the chart with the specified name
      var chart = $("#" + message.name).highcharts();
      var series = chart.series;

      // Add a new point
      series[0].addPoint([Number(message.x), Number(message.y0)], false, true);
      series[1].addPoint([Number(message.x), Number(message.y1)], false, true);
      chart.redraw();
    }
  );
});
