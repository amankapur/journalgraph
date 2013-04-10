$(function(){

	$(".magic").on('click', function(){
		query = $('input').val();
		console.log(query);
		
		$.post('/query', {query: query}, function(data){


			console.log($(data).find('table'));

			$(".results").html($(data).find('table'));

		});

	});

});