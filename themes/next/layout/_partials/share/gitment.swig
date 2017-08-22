{% set username = theme.gitment.username %}
{% set client_id = theme.gitment.client_id %}
{% set client_secret = theme.gitment.client_secret %}
<link rel="stylesheet" href="https://imsun.github.io/gitment/style/default.css">
<script src="https://imsun.github.io/gitment/dist/gitment.browser.js"></script>
<script>
  var gitment = new Gitment({
    id: window.location.pathname,
    owner: '{{username}}',
    repo: '{{username}}.github.io',
    oauth: {
    client_id: '{{client_id}}',
    client_secret: '{{client_secret}}'
    }
  });
  gitment.render('gitment_container');
</script>
