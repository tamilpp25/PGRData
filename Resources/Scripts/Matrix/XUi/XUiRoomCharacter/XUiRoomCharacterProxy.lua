-- 通用出战界面代理管理
XUiRoomCharacterProxy = XUiRoomCharacterProxy or {}

XUiRoomCharacterProxy.ProxyDic = {}
--=================
-- 注册出战界面代理
--@param stageType:FubenManager中关卡的分类StageType
--@param proxy:代理
--=================
function XUiRoomCharacterProxy.RegisterProxy(stageType, proxy)
    if XUiRoomCharacterProxy.ProxyDic[stageType] then return end
    XUiRoomCharacterProxy.ProxyDic[stageType] = proxy
end

--[[
--============================================================
--                         页面代理方法
--============================================================
所有方法都可选择性使用，不写该方法会调用UiRoomCharacter本身的默认方法
代理需使用上面的注册方法才能使用(一个FubenManager的StageType分类代理只有一个)
如有需要追加的方法请在下方补充

--================
--初始化左侧界面
--================
function ProxyName:InitCharacterTypeBtns(roomCharacterUi, teamCharIdMap, TabBtnIndex)

--================
--成员排序函数
--================
function ProxyName:SortList(roomCharacterUi, charIdList)

--================
--设置右侧界面显示
--================
function ProxyName:SetPanelEmptyList(roomCharacterUi, isEmpty)

--================
--刷新右侧界面
--================
function ProxyName:UpdatePanelEmptyList(roomCharacterUi)

--================
--刷新进战按钮
--================
function ProxyName:UpdateTeamBtn(roomCharacterUi, charId)

--================
--接受到活动重置或结束消息时
--================
function ProxyName:OnResetEvent(roomCharacterUi)

--================
--获取角色信息
--================
function ProxyName:GetCharInfo(roomCharacterUi, charId)

--]]