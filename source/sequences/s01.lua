s01 = {
    showAdvanceControl = false, --this ensures the right arrow does not appear to signify to move to the next scene
    advanceControl = Panels.Input.A, --A is used to move to next scene
    scrollType = Panels.ScrollType.AUTO, --should have the panel scroll automatically on a button press
    panels = {
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A, --shows the A button for each panel
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/1-mountains.png", parallex = 0.5},
				{ image = "comicImages/1-horizon.png", parallex = 0.5},
                { image = "comicImages/1-city.png", parallex = 0.5},
				{ image = "comicImages/1-ledge.png", parallex = 0.5},
				{ image = "comicImages/1-man.png", parallex = 0.5}
				
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5}, --layers are arranged back to front, so start with background and finish with the characters
                { image = "comicImages/1-mountains.png", parallex = 0.5},
                { image = "comicImages/2-ledge.png", parallex = 0.5},
                { image = "comicImages/2-phone.png", parallex = 0.5} --starting layers should have higher parallex values than the ones below
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/1-mountains.png", parallex = 0.5},
                { image = "comicImages/3-building.png", parallex = 0.5},
                { image = "comicImages/3-man.png", parallex = 0.5},
                { image = "comicImages/3-bubble.png", parallex = 0.5}
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/1-mountains.png", parallex = 0.5},
				{ image = "comicImages/1-horizon.png", parallex = 0.5},
                { image = "comicImages/1-city.png", parallex = 0.5},
				{ image = "comicImages/1-ledge.png", parallex = 0.5},
                { image = "assets/images/comicImages/4-bubble.png", parallex = 0.5}
            }
        }
    }
}