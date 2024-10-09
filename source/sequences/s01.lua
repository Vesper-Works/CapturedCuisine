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
                { image = "comicImages/CutsceneSprite1.png", parallex = 0.5}
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5}, --layers are arranged back to front, so start with background and finish with the characters
                { image = "comicImages/CutsceneSprite2.png", parallex = 0.5}
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/CutsceneSprite3.png", parallex = 0.5}
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/CutsceneSprite4.png", parallex = 0.5}
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/CutsceneSprite5.png", parallex = 0.5}
            }
        },
        {
            showAdvanceControl = true,
            advanceControlPosition = {x = 20, y = 20},
            advanceControl = Panels.Input.A,
            layers = {
                { image = "comicImages/sky.png", parallex = 0.5},
                { image = "comicImages/CutsceneSprite6.png", parallex = 0.5}
            }
        }
    }
}