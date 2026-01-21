//
//  YouTyubePlayerView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = [] // allow play inline (still user gesture for sound sometimes)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let vid = videoId.trimmingCharacters(in: .whitespacesAndNewlines)

        let html = """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <!-- Helps avoid referrer-related embed failures in some setups -->
            <meta name="referrer" content="strict-origin-when-cross-origin">
            <style>
              html, body { margin:0; padding:0; background:#000; height:100%; }
              .wrap { position:fixed; top:0; left:0; right:0; bottom:0; }
              iframe { width:100%; height:100%; border:0; }
            </style>
          </head>
          <body>
            <div class="wrap">
              <iframe
                src="https://www.youtube-nocookie.com/embed/\(vid)?playsinline=1&modestbranding=1&rel=0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
              </iframe>
            </div>
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }

}
