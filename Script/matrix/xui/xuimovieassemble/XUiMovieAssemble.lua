local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiMovieAssemble = XLuaUiManager.Register(XLuaUi, "UiMovieAssemble")
local XUiMovieAssembleStage = require("XUi/XUiMovieAssemble/XUiMovieAssembleStage")


function XUiMovieAssemble:OnStart(assembleId)
    self.StagePool = {}
    self.AssembleId = assembleId
    self:Refresh()
end

function XUiMovieAssemble:OnDestroy()
    self:ReleaseResource()
end

function XUiMovieAssemble:Refresh()
    local bgImgUrl = XMovieAssembleConfig.GetBgImgUrlById(self.AssembleId)
    if bgImgUrl and bgImgUrl ~= "" then
        self.RImgBg:SetRawImage(bgImgUrl)
    end

    local uiPrefabUrl = XMovieAssembleConfig.GetUiPrefabById(self.AssembleId)
    if uiPrefabUrl and uiPrefabUrl ~= "" then
        local uiPrefab = self.UiPrefabRoot:LoadPrefab(uiPrefabUrl)
        if uiPrefab then
            self:InitUiPrefab(uiPrefab, function ()
                if self.BtnBack then
                    self.BtnBack.CallBack = function () self:Close() end
                end
                if self.BtnMainUi then
                    self.BtnMainUi.CallBack = function () XLuaUiManager.RunMain() end
                end

                self:RefreshContent()
            end)
        end
    end
end

function XUiMovieAssemble:InitUiPrefab(uiPrefab, cb) -- 把Ui预制体的引用添加到父UI上
    local obj = uiPrefab.transform:GetComponent("UiObject")
    if obj ~= nil then
        for i = 0, obj.NameList.Count - 1 do
            self[obj.NameList[i]] = obj.ObjList[i]
        end

        if cb then cb() end
    end
end

function XUiMovieAssemble:RefreshContent()
    self:ReleaseResource()
    if self.PanelStageContent then
        local stagePrefabUrl = XMovieAssembleConfig.GetMovieTmpPrefabById(self.AssembleId)
        self.Resource = CS.XResourceManager.Load(stagePrefabUrl)
        local movieIds = XMovieAssembleConfig.GetMovieTmpIdsById(self.AssembleId)
        local onCreat = function (item, movieId)
            item:OnCreat(movieId)
        end

        XUiHelper.CreateTemplates(self, self.StagePool, movieIds, XUiMovieAssembleStage.New, self.Resource.Asset, self.PanelStageContent, onCreat)
    end
end

function XUiMovieAssemble:PlayMovie(movieId)
    local storyId = XMovieAssembleConfig.GetMovieIdById(movieId)
    XDataCenter.MovieManager.PlayMovie(storyId)
    XSaveTool.SaveData(string.format("%s%s%s", XMovieAssembleConfig.MovieAssembleWatchedKey, XPlayer.Id, movieId), XMovieAssembleConfig.MovieWatchedState.Watched)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_ASSEMBLE_WATCH_MOVIE)
end

-- 释放资源
function XUiMovieAssemble:ReleaseResource()
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
end