---@class XUiGuildDormFurnitureMovieCommon : XUiGuildDormFurnitureMovieBase
local XUiGuildDormFurnitureMovieCommon = XLuaUiManager.Register(require('XUi/XUiGuildDorm/UiFurnitureMovie/XUiGuildDormFurnitureMovieBase'), 'UiGuildDormFurnitureMovieCommon')

function XUiGuildDormFurnitureMovieCommon:OnAwake()
    self.Super.OnAwake(self)
    self:SetOptionCallBackProxyFunc(handler(self, self.OnBtnOptionClickProxyDefault))
end

function XUiGuildDormFurnitureMovieCommon:OnStart(furnitureId, recordCb)
    local interactionCfg = XGuildDormConfig.GetFurnitureInteraction(furnitureId)
    ---@type XTableGuildDormFurniture
    local furnitureCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Furniture, furnitureId)
    
    self._InteractionCfg = interactionCfg

    self:SetDialog(furnitureCfg.Name, interactionCfg.InteractionText)
    self:SetOptions(interactionCfg.ReplyTexts)
    
    self._RecordCb = recordCb
end

function XUiGuildDormFurnitureMovieCommon:OnBtnOptionClickProxyDefault(index)
    --服务端那边的索引是从0开始。lua这边是1开始，需要修正
    local fixedIndex= index - 1
    
    XDataCenter.GuildDormManager.RequestGuildDormRecordInteract(self._InteractionCfg.Id, self._RecordCb)
    
    if XTool.IsNumberValid(self._InteractionCfg.ReplyRewardIds[index]) and not XDataCenter.GuildDormManager.CheckHasRecieveReward(self._InteractionCfg.Id, fixedIndex) then
        XDataCenter.GuildDormManager.RequestGuildDormGetOneTimeInteractReward(self._InteractionCfg.Id, fixedIndex, function(data)
            XUiManager.OpenUiObtain(data, nil, handler(self, self.Close))
        end)
    else
        self:Close()
    end
    
end


return XUiGuildDormFurnitureMovieCommon