module Helper
  def hint
    @request.cookies['hint']
  end

  def condition_for_save
    (win? || @game.available_attempts.zero?) && !agree_to_save
  end

  def win?
    @results.last == '++++'
  end

end