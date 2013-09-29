: cascade base
: around content -> {
<canvas id="myChart" width="300" height="300"></canvas>

<script type="text/javascript">
	var data = {
	    labels:[
		"<: $week[0] :>",
		"<: $week[1] :>",
		"<: $week[2] :>",
		"<: $week[3] :>",
		"<: $week[4] :>",
		"<: $week[5] :>",
		"<: $week[6] :>",
		],
	    datasets:[
		{
			fillColor: "rgba(151,187,205,0.5)",
			strokeColor: "rgba(151,187,205,1)",
			pointColor:"rgba(151,187,205,1)",
			pointStrokeColor: "#fff",
			data: [
			      : for $busy_point -> $point{
			      <: $point :> , 
			      :}
			      ]
			}
		]
	}		
        var chart = new Chart(
	    document.getElementById("myChart").getContext("2d")
	    ).Line(data);    	
</script>
:}


