class MediaController < ApplicationController
  def index
    @media = Media.all
  end

  def show
    @media = Media.find(params[:id])
  end

  def new
    @media = Media.new
  end

  def create
    @media = Media.new(params[:media])
    if @media.save
      redirect_to @media, :notice => "Successfully created media."
    else
      render :action => 'new'
    end
  end

  def edit
    @media = Media.find(params[:id])
  end

  def update
    @media = Media.find(params[:id])
    if @media.update_attributes(params[:media])
      redirect_to @media, :notice  => "Successfully updated media."
    else
      render :action => 'edit'
    end
  end

  def destroy
    @media = Media.find(params[:id])
    @media.destroy
    redirect_to media_index_url, :notice => "Successfully destroyed media."
  end
  
  def search
    term = params[:term]
    @media = Media.where(["title LIKE :term OR description LIKE :term", { :term => "%#{term}%" }]) 
    render :action => 'index'
  end
  
  def scan
    code = params[:upc]
    response = if code.length >= 10
      Amazon::Ecs.item_lookup( code, :id_type => 'ISBN', :search_index => 'Books', :response_group => 'Large,AlternateVersions' )
    else
      Amazon::Ecs.item_lookup( code, :response_group => 'Large' )
    end
    if response
      item = response.items.first
      # File.open( Rails.root.join('tmp','response.xml'),'w') do |dump|
      #   dump.puts response.doc.to_s
      # end
      media = Media.new(
        :title       => item.get_unescaped('ItemAttributes/Title'),
        :description => item.get_unescaped('EditorialReviews[1]/EditorialReview/Content'),
        :isbn        => item.get_unescaped('ItemAttributes/ISBN'),
        :asin        => item.get_unescaped('ASIN'),
        :image_url   => item.get_unescaped('LargeImage/URL')
      )
      if publisher = Publisher.find_or_create_by_name( item.get_unescaped('ItemAttributes/Publisher') )
        media.publisher = publisher
      end
      if media.save
        authors = item.get_elements('ItemAttributes/Author') || []
        authors.each do |author_name|
          author = Author.find_or_create_by_name( author_name.get_unescaped() )
          media.authors << author
        end
      end
    end
    redirect_to media_index_url, :notice => "Imported"
  end
  
end
