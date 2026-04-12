defmodule AlbuminumWeb.UserSessionHTML do
  use AlbuminumWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:albuminum, Albuminum.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
