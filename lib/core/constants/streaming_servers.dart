/// All streaming server configurations — a 1:1 port of the web app's
/// `Watch.jsx` `BACKENDS` + `SERVER_CONFIGS` arrays.
///
/// Each [StreamingBackend] knows how to build a movie URL and a TV URL
/// (with season/episode). Each [StreamingServer] is a named, branded
/// entry the user picks from in the player's server menu.
///
/// The embeds are loaded inside a WebView — identical to the web app's
/// `<iframe>` approach, just rendered natively on Android.
class StreamingServer {
  const StreamingServer({
    required this.id,
    required this.name,
    required this.flag,
    required this.backend,
    this.adMode = AdMode.standard,
  });

  final String id;
  final String name;
  final ServerFlag flag;
  final StreamingBackend backend;
  final AdMode adMode;

  /// Builds the embed URL for a movie.
  String movieUrl(String id) => backend.movieUrl(id);

  /// Builds the embed URL for a TV episode.
  String tvUrl(String id, int season, int episode) =>
      backend.tvUrl(id, season, episode);

  /// True when this server is advertised as ad-free.
  bool get isAdFree => adMode == AdMode.adFree;
}

/// Visual marker shown next to a server in the picker.
enum ServerFlag { zap, star, us, india, uk, australia, shield }

/// Whether a server is marketed as ad-free.
enum AdMode { standard, adFree }

/// A genuinely distinct embed provider.
class StreamingBackend {
  const StreamingBackend({
    required this.movieUrl,
    required this.tvUrl,
    required this.checkUrl,
  });

  final String Function(String id) movieUrl;
  final String Function(String id, int season, int episode) tvUrl;
  final String checkUrl;
}

// ── 7 distinct embed providers ──
final List<StreamingBackend> _backends = [
  StreamingBackend(
    movieUrl: (id) => 'https://vidlink.pro/movie/$id',
    tvUrl: (id, s, e) => 'https://vidlink.pro/tv/$id/$s/$e',
    checkUrl: 'https://vidlink.pro',
  ),
  StreamingBackend(
    movieUrl: (id) => 'https://vidsrc.me/embed/movie?tmdb=$id',
    tvUrl: (id, s, e) =>
        'https://vidsrc.me/embed/tv?tmdb=$id&season=$s&episode=$e',
    checkUrl: 'https://vidsrc.me',
  ),
  StreamingBackend(
    movieUrl: (id) => 'https://vidsrc.pro/embed/movie/$id',
    tvUrl: (id, s, e) => 'https://vidsrc.pro/embed/tv/$id/$s/$e',
    checkUrl: 'https://vidsrc.pro',
  ),
  StreamingBackend(
    movieUrl: (id) => 'https://vidsrc.cc/v2/embed/movie/$id',
    tvUrl: (id, s, e) => 'https://vidsrc.cc/v2/embed/tv/$id/$s/$e',
    checkUrl: 'https://vidsrc.cc',
  ),
  StreamingBackend(
    movieUrl: (id) => 'https://multiembed.mov/?video_id=$id&tmdb=1',
    tvUrl: (id, s, e) =>
        'https://multiembed.mov/?video_id=$id&tmdb=1&s=$s&e=$e',
    checkUrl: 'https://multiembed.mov',
  ),
  StreamingBackend(
    movieUrl: (id) => 'https://peachify.top/embed/movie/$id',
    tvUrl: (id, s, e) => 'https://peachify.top/embed/tv/$id/$s/$e',
    checkUrl: 'https://peachify.top',
  ),
  // ── VidFast — ad-free embed provider (no ads, no popups) ──
  StreamingBackend(
    movieUrl: (id) => 'https://vidfast.pro/movie/$id',
    tvUrl: (id, s, e) => 'https://vidfast.pro/tv/$id/$s/$e',
    checkUrl: 'https://vidfast.pro',
  ),
];

/// The branded server options the user sees (same names/flags as web),
/// plus VidFast as the ad-free option.
final List<StreamingServer> streamingServers = [
  StreamingServer(id: 'server-0', name: 'Peachify', flag: ServerFlag.zap, backend: _backends[5]),
  StreamingServer(id: 'server-1', name: 'Xstream', flag: ServerFlag.zap, backend: _backends[0]),
  StreamingServer(id: 'server-2', name: 'Xstream Pro', flag: ServerFlag.zap, backend: _backends[1]),
  StreamingServer(id: 'server-3', name: 'Xstream Premium', flag: ServerFlag.star, backend: _backends[2]),
  StreamingServer(id: 'server-4', name: 'Xstream Ultra', flag: ServerFlag.zap, backend: _backends[3]),
  StreamingServer(id: 'server-5', name: 'Xstream Max', flag: ServerFlag.zap, backend: _backends[4]),
  StreamingServer(id: 'server-6', name: 'Turbo', flag: ServerFlag.us, backend: _backends[0]),
  StreamingServer(id: 'server-7', name: 'NHD', flag: ServerFlag.india, backend: _backends[1]),
  StreamingServer(id: 'server-8', name: '4K', flag: ServerFlag.uk, backend: _backends[2]),
  StreamingServer(id: 'server-9', name: 'Premium', flag: ServerFlag.us, backend: _backends[3]),
  StreamingServer(id: 'server-10', name: 'MultiEmbed', flag: ServerFlag.australia, backend: _backends[4]),
  // ── Ad-free server (VidFast — no ads, no popups) ──
  StreamingServer(
    id: 'server-vidfast',
    name: 'VidFast',
    flag: ServerFlag.shield,
    backend: _backends[6],
    adMode: AdMode.adFree,
  ),
];

/// Default server (Peachify — index 0, matching the web app).
final StreamingServer defaultServer = streamingServers.first;

/// The ad-free server. The "Ad-Free" button switches to this one
/// automatically because VidFast does not serve ads.
final StreamingServer adFreeServer =
    streamingServers.firstWhere((s) => s.isAdFree, orElse: () => streamingServers.last);
