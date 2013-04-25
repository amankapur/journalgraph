$(function(){

	$(".magic").on('click', function(){
		query = $('input').val();
		console.log(query);
		
		$.post('/query', {query: query}, function(data){

			console.log(data);

			$(".results").html($(data).find('#articles'));

		});

	});

	$("#showall").on('click', function(){
		$.get('/showall', function(data){
			$(".results").html($(data).find('#articles'));
		});
	});

	$("body").on('click', ".related", function(){
		console.log('hi');
		id = $(this).attr('id');
		console.log(id);

		$.post('/getrelated', {'query': id}, function(data){
			$(".results").html($(data).find('#articles'));
		});
	});


});