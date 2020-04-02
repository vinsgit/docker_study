class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def create
    @post = Post.new(article_params)
    @post.save
    redirect_to @post
  end

  def show
    @post = Post.find(params[:id])
  end

  def update

  end
end

private
  def article_params
    params.require(:article).permit(:title,:text)
  end