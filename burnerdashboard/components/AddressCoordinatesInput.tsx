import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2, MapPin, Search } from "lucide-react";
import { toast } from "sonner";
import { geocodeAddress, parseCoordinates, formatCoordinates } from "@/lib/geocoding";

interface AddressCoordinatesInputProps {
  address: string;
  onAddressChange: (address: string) => void;
  city: string;
  onCityChange: (city: string) => void;
  latitude: string;
  onLatitudeChange: (latitude: string) => void;
  longitude: string;
  onLongitudeChange: (longitude: string) => void;
}

export function AddressCoordinatesInput({
  address,
  onAddressChange,
  city,
  onCityChange,
  latitude,
  onLatitudeChange,
  longitude,
  onLongitudeChange,
}: AddressCoordinatesInputProps) {
  const [geocoding, setGeocoding] = useState(false);
  const [coordinatesInput, setCoordinatesInput] = useState("");

  const handleGeocoding = async () => {
    if (!address.trim()) {
      toast.error("Please enter an address first");
      return;
    }

    setGeocoding(true);
    try {
      const result = await geocodeAddress(address);

      if (result) {
        onLatitudeChange(result.coordinates.latitude.toString());
        onLongitudeChange(result.coordinates.longitude.toString());

        // Update city if found and not already set
        if (result.city && !city) {
          onCityChange(result.city);
        }

        toast.success("Address geocoded successfully!");
      } else {
        toast.error("Could not find coordinates for this address");
      }
    } catch (error) {
      toast.error("Failed to geocode address");
    } finally {
      setGeocoding(false);
    }
  };

  const handleCoordinatesPaste = (value: string) => {
    setCoordinatesInput(value);

    // Try to parse coordinates
    const parsed = parseCoordinates(value);
    if (parsed) {
      onLatitudeChange(parsed.latitude.toString());
      onLongitudeChange(parsed.longitude.toString());
      toast.success("Coordinates parsed successfully!");
    }
  };

  return (
    <div className="space-y-4">
      {/* Address section with geocoding */}
      <div className="space-y-2">
        <Label htmlFor="address">Address (Optional)</Label>
        <div className="flex gap-2">
          <Input
            id="address"
            placeholder="123 Main Street, London, UK"
            value={address}
            onChange={(e) => onAddressChange(e.target.value)}
            className="flex-1"
          />
          <Button
            type="button"
            variant="outline"
            onClick={handleGeocoding}
            disabled={geocoding || !address.trim()}
          >
            {geocoding ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Search className="h-4 w-4" />
            )}
            <span className="ml-2 hidden sm:inline">Geocode</span>
          </Button>
        </div>
        <p className="text-xs text-muted-foreground">
          Enter an address and click "Geocode" to automatically fill coordinates
        </p>
      </div>

      <div className="space-y-2">
        <Label htmlFor="city">City (Optional)</Label>
        <Input
          id="city"
          placeholder="London"
          value={city}
          onChange={(e) => onCityChange(e.target.value)}
        />
      </div>

      {/* Quick coordinates paste */}
      <div className="space-y-2">
        <Label htmlFor="coordinates-paste">Quick Coordinates Paste</Label>
        <Input
          id="coordinates-paste"
          placeholder="51.5074, -0.1278"
          value={coordinatesInput}
          onChange={(e) => handleCoordinatesPaste(e.target.value)}
        />
        <p className="text-xs text-muted-foreground">
          Paste coordinates in format: "latitude, longitude" (e.g., "51.5074, -0.1278")
        </p>
      </div>

      {/* Separate lat/long fields */}
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="latitude">
            Latitude *
            {latitude && (
              <span className="ml-2 text-xs text-muted-foreground font-normal">
                ({parseFloat(latitude).toFixed(6)})
              </span>
            )}
          </Label>
          <Input
            id="latitude"
            type="number"
            step="any"
            placeholder="51.5074"
            value={latitude}
            onChange={(e) => onLatitudeChange(e.target.value)}
            required
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="longitude">
            Longitude *
            {longitude && (
              <span className="ml-2 text-xs text-muted-foreground font-normal">
                ({parseFloat(longitude).toFixed(6)})
              </span>
            )}
          </Label>
          <Input
            id="longitude"
            type="number"
            step="any"
            placeholder="-0.1278"
            value={longitude}
            onChange={(e) => onLongitudeChange(e.target.value)}
            required
          />
        </div>
      </div>

      {latitude && longitude && (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <MapPin className="h-4 w-4" />
          <span>
            Current coordinates: {formatCoordinates(parseFloat(latitude), parseFloat(longitude))}
          </span>
        </div>
      )}
    </div>
  );
}
