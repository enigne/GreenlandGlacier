% replace the thickness by Height above flotation
function H=replaceHab(thickness, bed, icemask, oceanmask, rho_water, rho_ice)
	% check the size of thickness, icemask, oceanmask
	if any(size(thickness) ~= size(icemask)) | any(size(thickness) ~= size(oceanmask))
		error(['Size of thickness is not the same as the masks']);
	end

	sealevel = 0;
	% remove no ice area
	thickness(icemask>=0) = 0;
	% remove floating ice
	thickness(oceanmask<=0) = 0;
	% replace 0 H ice by sea water (in ice equivalent)
	water = -min(sealevel, bed)*rho_water/rho_ice;
	water = repmat(water, 1, size(thickness,2));
	thickness(thickness == 0) = water(thickness == 0);
	H = thickness;
end
