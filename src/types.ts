/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface XtreamServer {
  id: string;
  name: string;
  host: string;
  username: string;
  password: string;
  createdAt: number;
}

export interface UserInfo {
  auth: number;
  status: string;
  exp_date?: string;
  active_cons?: string | number;
  max_connections?: string | number;
  allowed_output_formats?: string[];
  message?: string;
}

export interface ServerInfo {
  url?: string;
  port?: string;
  server_protocol?: string;
  rtmp_port?: string;
  timezone?: string;
  time_now?: string;
}

export interface ServerDetails {
  user_info?: UserInfo;
  server_info?: ServerInfo;
}

export interface IptvCategory {
  category_id: string;
  category_name: string;
  parent_id: number | string;
}

export interface IptvStream {
  num: number;
  name: string;
  stream_id: string | number;
  stream_icon?: string;
  epg_channel_id?: string;
  added?: string;
  category_id: string;
  custom_sid?: string;
  direct_source?: string;
  // Live specific
  stream_type?: string;
  // VOD specific
  container_extension?: string;
  rating?: string;
  rating_5rate?: number;
  // Series specific
  series_id?: string | number;
  releaseDate?: string;
  plot?: string;
  cast?: string;
  director?: string;
  genre?: string;
}

export interface IptvEpisode {
  id: string | number;
  episode_num: number | string;
  title: string;
  container_extension?: string;
  info?: {
    duration?: string;
    movie_image?: string;
    plot?: string;
    releasedate?: string;
  };
}

export interface SeriesSeasonsResponse {
  seasons: {
    air_date?: string;
    episode_count?: number;
    id?: number;
    name?: string;
    overview?: string;
    season_number?: number;
  }[];
  episodes: {
    [seasonNumber: string]: IptvEpisode[];
  };
  info: {
    name?: string;
    cover?: string;
    plot?: string;
    genre?: string;
    releaseDate?: string;
    director?: string;
    cast?: string;
    rating?: string;
  };
}

export type StreamMode = "live" | "movie" | "series";

export interface AppConfig {
  fontFamily: string;
  accentColor: string;
  sidebarCollapsed: boolean;
  density: "comfortable" | "compact";
  customPlayerScheme: string; // 'vlc' | 'potplayer' | 'copy' | 'm3u'
}

export const FONTS_LIST = [
  { id: "font-segoe", name: "Segoe UI & Inter (Windows UI)", css: '"Inter", sans-serif' },
  { id: "font-grotesk", name: "Space Grotesk (Tech Minimal)", css: '"Space Grotesk", sans-serif' },
  { id: "font-mono", name: "JetBrains Mono (Developer Console)", css: '"JetBrains Mono", monospace' },
  { id: "font-outfit", name: "Outfit (Playful Fluent UI)", css: '"Outfit", sans-serif' },
  { id: "font-serif", name: "Playfair Display (Serif / Executive)", css: '"Playfair Display", serif' }
];

export const ACCENTS_LIST = [
  { id: "blue", name: "Windows Sky Blue", color: "#0078d4", bgClass: "bg-[#0078d4]", textClass: "text-[#0078d4]", borderClass: "border-[#0078d4]" },
  { id: "xbox", name: "Xbox Lime Green", color: "#107c10", bgClass: "bg-[#107c10]", textClass: "text-[#107c10]", borderClass: "border-[#107c10]" },
  { id: "orange", name: "Sunset Orange", color: "#ca5010", bgClass: "bg-[#ca5010]", textClass: "text-[#ca5010]", borderClass: "border-[#ca5010]" },
  { id: "purple", name: "Windows Fluent Purple", color: "#8660a9", bgClass: "bg-[#8660a9]", textClass: "text-[#8660a9]", borderClass: "border-[#8660a9]" },
  { id: "slate", name: "Cosmic Slate Gray", color: "#4b5563", bgClass: "bg-gray-600", textClass: "text-gray-600", borderClass: "border-gray-600" }
];
