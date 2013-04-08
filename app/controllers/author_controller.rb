class AuthorController < ApplicationController
	def create
    @author = author.new(params[:author])
    puts 'dafuq###############'
    respond_to do |format|
      if @author.save
        format.html { redirect_to @author, notice: 'author was successfully created.' }
        format.json { render json: @author, status: :created, location: @author }
      else
        format.html { render action: "new" }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /authors/1
  # PUT /authors/1.json
  def update
    @author = author.find(params[:id])

    respond_to do |format|
      if @author.update_attributes(params[:author])
        format.html { redirect_to @author, notice: 'author was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /authors/1
  # DELETE /authors/1.json
  def destroy
    @author = author.find(params[:id])
    @author.destroy

    respond_to do |format|
      format.html { redirect_to authors_url }
      format.json { head :no_content }
    end
  end
end

end
