    function fuzzySearch(inPutText, appName) {
        let lowerInput = inPutText.toLowerCase();
        let lowerName = appName.toLowerCase();

        let inPutIndex = 0;

        for (let i = 0; i < lowerName.length; i++) {
            if (lowerName[i] === lowerInput[inPutIndex]) {
                inPutIndex++;
            }
            if (inPutIndex === lowerInput.length) {
                return true;
            }
        }

        return false;
    }