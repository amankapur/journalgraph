$(function(){

	$("#query").keypress(function(e){
		if(e.which == 13){
			doMagic();
		}
	});
	

	$(".magic").on('click', function(){
		doMagic();
	});	

	var doMagic = function(){
		query = $('#query').val();
		console.log(query);

		searchtype = $("input[type=radio]:checked").attr('id')
		console.log(searchtype);
		
		$.post('/query', {query: query, searchtype: searchtype}, function(data){

			console.log(data);

			$(".results").html($(data).find('#articles'));

		});

	}

	$("#showall").on('click', function(){
		$.get('/showall', function(data){
			$(".results").html($(data).find('#articles'));
		});
	});

	$("body").on('click', ".related", function(){
		// console.log('hi');
		id = $(this).attr('id');
		console.log(id);

		$.post('/getrelated', {'query': id}, function(data){
			$(".results").html($(data).find('#articles'));
		});
	});

	$("body").on('click', ".show_authors", function(){
		// console.log('hi');
		id = $(this).attr('id');
		console.log(id);

		$.post('/getauthors	', {'query': id}, function(data){
			$(".results").html($(data).find('#authors'));
		});
	});	

	$("body").on('click', ".get_works_author", function(){
		// console.log('hi');
		id = $(this).attr('id');
		console.log(id);

		$.post('/getworks	', {'query': id}, function(data){
			$(".results").html($(data).find('#articles'));
		});
	});	

	$("body").on('click', ".get_related_authors", function(){
		// console.log('hi');
		id = $(this).attr('id');
		console.log(id);

		$.post('/getrelatedauthors	', {'query': id}, function(data){
			$(".results").html($(data).find('#authors'));
		});
	});	

});