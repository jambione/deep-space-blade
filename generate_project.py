#!/usr/bin/env python3
"""
Generates DeepSpaceBlade.xcodeproj/project.pbxproj
Usage: python3 generate_project.py
"""
import hashlib, os, sys

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ_DIR = os.path.join(BASE, "DeepSpaceBlade.xcodeproj")
os.makedirs(PROJ_DIR, exist_ok=True)

def uid(seed):
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

APP_NAME   = "DeepSpaceBlade"
BUNDLE_ID  = "com.jmb.deepspaceblade"
DEPLOY_TGT = "16.0"
SWIFT_VER  = "5.0"

# ── file lists ──────────────────────────────────────────────────────────────

SOURCES = [
    ("DeepSpaceBlade/App/AppDelegate.swift",         "App"),
    ("DeepSpaceBlade/App/SceneDelegate.swift",        "App"),
    ("DeepSpaceBlade/App/GameViewController.swift",   "App"),
    ("DeepSpaceBlade/Scenes/GameScene.swift",         "Scenes"),
    ("DeepSpaceBlade/Scenes/MenuScene.swift",         "Scenes"),
    ("DeepSpaceBlade/Scenes/GameOverScene.swift",     "Scenes"),
    ("DeepSpaceBlade/Models/GameModels.swift",        "Models"),
    ("DeepSpaceBlade/Director/LevelDirector.swift",   "Director"),
    ("DeepSpaceBlade/Director/WaveDirector.swift",    "Director"),
    ("DeepSpaceBlade/Entities/PlayerShip.swift",      "Entities"),
    ("DeepSpaceBlade/Entities/EnemyNode.swift",       "Entities"),
    ("DeepSpaceBlade/Entities/ProjectilePool.swift",  "Entities"),
    ("DeepSpaceBlade/Systems/CollisionSystem.swift",  "Systems"),
    ("DeepSpaceBlade/Systems/MovementSystem.swift",   "Systems"),
    ("DeepSpaceBlade/State/GameState.swift",          "State"),
]

RESOURCES = [
    ("DeepSpaceBlade/Resources/levels.json",      "Resources"),
    ("DeepSpaceBlade/Resources/blueprints.json",  "Resources"),
    ("DeepSpaceBlade/Assets.xcassets",             "DeepSpaceBlade"),
]

PLIST_PATH = "DeepSpaceBlade/App/Info.plist"
FRAMEWORKS = ["SpriteKit", "AVFoundation"]
GROUPS = ["App", "Scenes", "Models", "Director", "Entities", "Systems", "State", "Resources"]

# ── UID helpers ──────────────────────────────────────────────────────────────

def fr(path):   return uid("fileref:" + path)
def bf(path):   return uid("buildfile:" + path)
def grp(name):  return uid("group:" + name)
def fw_fr(name):return uid("fwref:" + name)
def fw_bf(name):return uid("fwbf:" + name)

# fixed UIDs
U_ROOT_GRP        = uid("rootgroup")
U_PRODUCTS_GRP    = uid("productsgroup")
U_SOURCES_PHASE   = uid("sourcesphase")
U_RESOURCES_PHASE = uid("resourcesphase")
U_FRAMEWORKS_PHASE= uid("frameworksphase")
U_TARGET          = uid("target")
U_PROJECT         = uid("project")
U_PRODUCT_FR      = uid("productfr")
U_DEBUG_PROJ      = uid("debug_proj")
U_RELEASE_PROJ    = uid("release_proj")
U_DEBUG_TGT       = uid("debug_tgt")
U_RELEASE_TGT     = uid("release_tgt")
U_CFGLIST_PROJ    = uid("cfglist_proj")
U_CFGLIST_TGT     = uid("cfglist_tgt")
U_PLIST_FR        = uid("plistfr")

# ── build settings ───────────────────────────────────────────────────────────

PROJ_DEBUG = f"""\
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

PROJ_RELEASE = f"""\
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;"""

TGT_COMMON = f"""\
\t\t\t\tASPLASHSCREEN_BACKGROUND_COLOR = "0x000000";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "{PLIST_PATH}";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOY_TGT};
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 0.1;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = {SWIFT_VER};
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tASPLASHSCREEN_BACKGROUND_COLOR = "0x000000";"""

# ── assemble pbxproj ─────────────────────────────────────────────────────────

def pbxproj():
    lines = []
    W = lines.append

    W("// !$*UTF8*$!")
    W("{")
    W("\tarchiveVersion = 1;")
    W("\tclasses = {};")
    W("\tobjectVersion = 56;")
    W("\tobjects = {")
    W("")

    # ── PBXBuildFile ──
    W("/* Begin PBXBuildFile section */")
    for path, _ in SOURCES:
        fname = os.path.basename(path)
        W(f"\t\t{bf(path)} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr(path)} /* {fname} */; }};")
    for path, _ in RESOURCES:
        fname = os.path.basename(path)
        W(f"\t\t{bf(path)} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {fr(path)} /* {fname} */; }};")
    for fw in FRAMEWORKS:
        W(f"\t\t{fw_bf(fw)} /* {fw}.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fw_fr(fw)} /* {fw}.framework */; }};")
    W("/* End PBXBuildFile section */")
    W("")

    # ── PBXFileReference ──
    W("/* Begin PBXFileReference section */")
    W(f"\t\t{U_PRODUCT_FR} /* {APP_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    W(f"\t\t{U_PLIST_FR} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    for path, _ in SOURCES:
        fname = os.path.basename(path)
        W(f"\t\t{fr(path)} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};")
    for path, _ in RESOURCES:
        fname = os.path.basename(path)
        if path.endswith(".xcassets"):
            # Use SOURCE_ROOT + full relative path so actool always finds it
            W(f"\t\t{fr(path)} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {path}; sourceTree = SOURCE_ROOT; }};")
        else:
            ft = "text.json" if path.endswith(".json") else "text"
            W(f"\t\t{fr(path)} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = {fname}; sourceTree = \"<group>\"; }};")
    for fw in FRAMEWORKS:
        W(f"\t\t{fw_fr(fw)} /* {fw}.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {fw}.framework; path = System/Library/Frameworks/{fw}.framework; sourceTree = SDKROOT; }};")
    W("/* End PBXFileReference section */")
    W("")

    # ── PBXFrameworksBuildPhase ──
    W("/* Begin PBXFrameworksBuildPhase section */")
    W(f"\t\t{U_FRAMEWORKS_PHASE} /* Frameworks */ = {{")
    W(f"\t\t\tisa = PBXFrameworksBuildPhase;")
    W(f"\t\t\tbuildActionMask = 2147483647;")
    W(f"\t\t\tfiles = (")
    for fw in FRAMEWORKS:
        W(f"\t\t\t\t{fw_bf(fw)} /* {fw}.framework in Frameworks */,")
    W(f"\t\t\t);")
    W(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    W(f"\t\t}};")
    W("/* End PBXFrameworksBuildPhase section */")
    W("")

    # ── PBXGroup ──
    W("/* Begin PBXGroup section */")

    # Root group
    W(f"\t\t{U_ROOT_GRP} = {{")
    W(f"\t\t\tisa = PBXGroup;")
    W(f"\t\t\tchildren = (")
    W(f"\t\t\t\t{grp(APP_NAME)} /* {APP_NAME} */,")
    W(f"\t\t\t\t{grp('Frameworks')} /* Frameworks */,")
    W(f"\t\t\t\t{U_PRODUCTS_GRP} /* Products */,")
    W(f"\t\t\t);")
    W(f"\t\t\tsourceTree = \"<group>\";")
    W(f"\t\t}};")

    # Products group
    W(f"\t\t{U_PRODUCTS_GRP} /* Products */ = {{")
    W(f"\t\t\tisa = PBXGroup;")
    W(f"\t\t\tchildren = (")
    W(f"\t\t\t\t{U_PRODUCT_FR} /* {APP_NAME}.app */,")
    W(f"\t\t\t);")
    W(f"\t\t\tname = Products;")
    W(f"\t\t\tsourceTree = \"<group>\";")
    W(f"\t\t}};")

    # Frameworks group
    W(f"\t\t{grp('Frameworks')} /* Frameworks */ = {{")
    W(f"\t\t\tisa = PBXGroup;")
    W(f"\t\t\tchildren = (")
    for fw in FRAMEWORKS:
        W(f"\t\t\t\t{fw_fr(fw)} /* {fw}.framework */,")
    W(f"\t\t\t);")
    W(f"\t\t\tname = Frameworks;")
    W(f"\t\t\tsourceTree = \"<group>\";")
    W(f"\t\t}};")

    # Main DeepSpaceBlade group — includes sub-groups + top-level resources (e.g. xcassets)
    top_level_res = [(p, g) for p, g in RESOURCES if g == APP_NAME]
    W(f"\t\t{grp(APP_NAME)} /* {APP_NAME} */ = {{")
    W(f"\t\t\tisa = PBXGroup;")
    W(f"\t\t\tchildren = (")
    for g in GROUPS:
        W(f"\t\t\t\t{grp(g)} /* {g} */,")
    for path, _ in top_level_res:
        W(f"\t\t\t\t{fr(path)} /* {os.path.basename(path)} */,")
    W(f"\t\t\t);")
    W(f"\t\t\tpath = {APP_NAME};")
    W(f"\t\t\tsourceTree = \"<group>\";")
    W(f"\t\t}};")


    # Sub-groups
    for g in GROUPS:
        members_src = [(p, grp_) for p, grp_ in SOURCES   if grp_ == g]
        members_res = [(p, grp_) for p, grp_ in RESOURCES if grp_ == g]
        W(f"\t\t{grp(g)} /* {g} */ = {{")
        W(f"\t\t\tisa = PBXGroup;")
        W(f"\t\t\tchildren = (")
        for path, _ in members_src:
            W(f"\t\t\t\t{fr(path)} /* {os.path.basename(path)} */,")
        for path, _ in members_res:
            W(f"\t\t\t\t{fr(path)} /* {os.path.basename(path)} */,")
        if g == "App":
            W(f"\t\t\t\t{U_PLIST_FR} /* Info.plist */,")
        W(f"\t\t\t);")
        W(f"\t\t\tpath = {g};")
        W(f"\t\t\tsourceTree = \"<group>\";")
        W(f"\t\t}};")

    W("/* End PBXGroup section */")
    W("")

    # ── PBXNativeTarget ──
    W("/* Begin PBXNativeTarget section */")
    W(f"\t\t{U_TARGET} /* {APP_NAME} */ = {{")
    W(f"\t\t\tisa = PBXNativeTarget;")
    W(f"\t\t\tbuildConfigurationList = {U_CFGLIST_TGT} /* Build configuration list for PBXNativeTarget \"{APP_NAME}\" */;")
    W(f"\t\t\tbuildPhases = (")
    W(f"\t\t\t\t{U_SOURCES_PHASE} /* Sources */,")
    W(f"\t\t\t\t{U_RESOURCES_PHASE} /* Resources */,")
    W(f"\t\t\t\t{U_FRAMEWORKS_PHASE} /* Frameworks */,")
    W(f"\t\t\t);")
    W(f"\t\t\tbuildRules = ();")
    W(f"\t\t\tdependencies = ();")
    W(f"\t\t\tname = {APP_NAME};")
    W(f"\t\t\tproductName = {APP_NAME};")
    W(f"\t\t\tproductReference = {U_PRODUCT_FR} /* {APP_NAME}.app */;")
    W(f"\t\t\tproductType = \"com.apple.product-type.application\";")
    W(f"\t\t}};")
    W("/* End PBXNativeTarget section */")
    W("")

    # ── PBXProject ──
    W("/* Begin PBXProject section */")
    W(f"\t\t{U_PROJECT} /* Project object */ = {{")
    W(f"\t\t\tisa = PBXProject;")
    W(f"\t\t\tattributes = {{")
    W(f"\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    W(f"\t\t\t\tLastSwiftUpdateCheck = 1540;")
    W(f"\t\t\t\tLastUpgradeCheck = 1540;")
    W(f"\t\t\t\tTargetAttributes = {{")
    W(f"\t\t\t\t\t{U_TARGET} = {{")
    W(f"\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;")
    W(f"\t\t\t\t\t}};")
    W(f"\t\t\t\t}};")
    W(f"\t\t\t}};")
    W(f"\t\t\tbuildConfigurationList = {U_CFGLIST_PROJ} /* Build configuration list for PBXProject \"{APP_NAME}\" */;")
    W(f"\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    W(f"\t\t\tdevelopmentRegion = en;")
    W(f"\t\t\thasScannedForEncodings = 0;")
    W(f"\t\t\tknownRegions = (en, Base);")
    W(f"\t\t\tmainGroup = {U_ROOT_GRP};")
    W(f"\t\t\tproductRefGroup = {U_PRODUCTS_GRP} /* Products */;")
    W(f"\t\t\tprojectDirPath = \"\";")
    W(f"\t\t\tprojectRoot = \"\";")
    W(f"\t\t\ttargets = (")
    W(f"\t\t\t\t{U_TARGET} /* {APP_NAME} */,")
    W(f"\t\t\t);")
    W(f"\t\t}};")
    W("/* End PBXProject section */")
    W("")

    # ── PBXResourcesBuildPhase ──
    W("/* Begin PBXResourcesBuildPhase section */")
    W(f"\t\t{U_RESOURCES_PHASE} /* Resources */ = {{")
    W(f"\t\t\tisa = PBXResourcesBuildPhase;")
    W(f"\t\t\tbuildActionMask = 2147483647;")
    W(f"\t\t\tfiles = (")
    for path, _ in RESOURCES:
        W(f"\t\t\t\t{bf(path)} /* {os.path.basename(path)} in Resources */,")
    W(f"\t\t\t);")
    W(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    W(f"\t\t}};")
    W("/* End PBXResourcesBuildPhase section */")
    W("")

    # ── PBXSourcesBuildPhase ──
    W("/* Begin PBXSourcesBuildPhase section */")
    W(f"\t\t{U_SOURCES_PHASE} /* Sources */ = {{")
    W(f"\t\t\tisa = PBXSourcesBuildPhase;")
    W(f"\t\t\tbuildActionMask = 2147483647;")
    W(f"\t\t\tfiles = (")
    for path, _ in SOURCES:
        W(f"\t\t\t\t{bf(path)} /* {os.path.basename(path)} in Sources */,")
    W(f"\t\t\t);")
    W(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    W(f"\t\t}};")
    W("/* End PBXSourcesBuildPhase section */")
    W("")

    # ── XCBuildConfiguration ──
    W("/* Begin XCBuildConfiguration section */")

    W(f"\t\t{U_DEBUG_PROJ} /* Debug */ = {{")
    W(f"\t\t\tisa = XCBuildConfiguration;")
    W(f"\t\t\tbuildSettings = {{")
    W(PROJ_DEBUG)
    W(f"\t\t\t}};")
    W(f"\t\t\tname = Debug;")
    W(f"\t\t}};")

    W(f"\t\t{U_RELEASE_PROJ} /* Release */ = {{")
    W(f"\t\t\tisa = XCBuildConfiguration;")
    W(f"\t\t\tbuildSettings = {{")
    W(PROJ_RELEASE)
    W(f"\t\t\t}};")
    W(f"\t\t\tname = Release;")
    W(f"\t\t}};")

    W(f"\t\t{U_DEBUG_TGT} /* Debug */ = {{")
    W(f"\t\t\tisa = XCBuildConfiguration;")
    W(f"\t\t\tbuildSettings = {{")
    W(TGT_COMMON)
    W(f"\t\t\t}};")
    W(f"\t\t\tname = Debug;")
    W(f"\t\t}};")

    W(f"\t\t{U_RELEASE_TGT} /* Release */ = {{")
    W(f"\t\t\tisa = XCBuildConfiguration;")
    W(f"\t\t\tbuildSettings = {{")
    W(TGT_COMMON)
    W(f"\t\t\t}};")
    W(f"\t\t\tname = Release;")
    W(f"\t\t}};")

    W("/* End XCBuildConfiguration section */")
    W("")

    # ── XCConfigurationList ──
    W("/* Begin XCConfigurationList section */")
    W(f"\t\t{U_CFGLIST_PROJ} /* Build configuration list for PBXProject \"{APP_NAME}\" */ = {{")
    W(f"\t\t\tisa = XCConfigurationList;")
    W(f"\t\t\tbuildConfigurations = (")
    W(f"\t\t\t\t{U_DEBUG_PROJ} /* Debug */,")
    W(f"\t\t\t\t{U_RELEASE_PROJ} /* Release */,")
    W(f"\t\t\t);")
    W(f"\t\t\tdefaultConfigurationIsVisible = 0;")
    W(f"\t\t\tdefaultConfigurationName = Release;")
    W(f"\t\t}};")
    W(f"\t\t{U_CFGLIST_TGT} /* Build configuration list for PBXNativeTarget \"{APP_NAME}\" */ = {{")
    W(f"\t\t\tisa = XCConfigurationList;")
    W(f"\t\t\tbuildConfigurations = (")
    W(f"\t\t\t\t{U_DEBUG_TGT} /* Debug */,")
    W(f"\t\t\t\t{U_RELEASE_TGT} /* Release */,")
    W(f"\t\t\t);")
    W(f"\t\t\tdefaultConfigurationIsVisible = 0;")
    W(f"\t\t\tdefaultConfigurationName = Release;")
    W(f"\t\t}};")
    W("/* End XCConfigurationList section */")
    W("")

    W("\t};")
    W(f"\trootObject = {U_PROJECT} /* Project object */;")
    W("}")

    return "\n".join(lines)


out = os.path.join(PROJ_DIR, "project.pbxproj")
with open(out, "w") as f:
    f.write(pbxproj())

print(f"✓ Generated {out}")
print(f"  Open with: open DeepSpaceBlade.xcodeproj")
