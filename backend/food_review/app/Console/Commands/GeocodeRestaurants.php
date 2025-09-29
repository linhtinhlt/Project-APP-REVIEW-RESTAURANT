<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use App\Models\Restaurant;

class GeocodeRestaurants extends Command
{
    protected $signature = 'restaurants:geocode';
    protected $description = 'Geocode all restaurants without latitude/longitude';

    public function handle()
    {
        // Lấy token Mapbox từ config
        $mapToken = config('services.mapbox.token');

        $restaurants = Restaurant::whereNull('latitude')
                                 ->orWhereNull('longitude')
                                 ->get();

        $this->info("Found {$restaurants->count()} restaurants to geocode.");

        foreach ($restaurants as $restaurant) {
            $address = rawurlencode($restaurant->address); // sửa ở đây
            $url = "https://api.mapbox.com/geocoding/v5/mapbox.places/{$address}.json?access_token={$mapToken}&limit=1";

            $response = Http::get($url);
            $data = $response->json();

            if (isset($data['features']) && count($data['features']) > 0) {
                // Cố gắng lấy feature type "address"
                $feature = collect($data['features'])->firstWhere('place_type.0', 'address');

                // Nếu không có feature "address", lấy feature đầu tiên
                if (!$feature) {
                    $feature = $data['features'][0];
                    $this->warn("Using first feature for {$restaurant->name} instead of precise address.");
                }

                $coords = $feature['center']; // [lng, lat]
                $restaurant->longitude = $coords[0];
                $restaurant->latitude = $coords[1];
                $restaurant->save();

                $this->info("Updated {$restaurant->name}: lat={$coords[1]}, lng={$coords[0]}");
            } else {
                $this->warn("No features returned for {$restaurant->name}");
                $this->line("URL tried: {$url}");
            }
        }

        $this->info('Geocoding completed.');
    }
}
