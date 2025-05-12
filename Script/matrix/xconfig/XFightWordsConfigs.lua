XFightWordsConfigs = XFightWordsConfigs or {}

local TABLE_MOVIE_PATH_PREFIX = "Client/Fight/Words/Words.tab"
local WordsTemplates

local function InitWordsTemplate(id)
	if not WordsTemplates then
		WordsTemplates = {}
		local wordsArray = XTableManager.ReadAllByIntKey(TABLE_MOVIE_PATH_PREFIX, XTable.XTableFightWords)
		for i = 1, #wordsArray do
			local group = wordsArray[i]["Group"]
			if not WordsTemplates[group] then
				WordsTemplates[group] = {}
			end
			table.insert(WordsTemplates[group],wordsArray[i])
		end
	end
end

function XFightWordsConfigs.GetMovieCfg(id)
	if not WordsTemplates then 
		InitWordsTemplate(id)
	end
    return WordsTemplates[id]
end