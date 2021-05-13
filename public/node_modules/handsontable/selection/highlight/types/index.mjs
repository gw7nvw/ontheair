function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { _defineProperty(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import staticRegister from "./../../../utils/staticRegister.mjs";
import activeHeaderHighlight from "./activeHeader.mjs";
import areaHighlight from "./area.mjs";
import cellHighlight from "./cell.mjs";
import customSelection from "./customSelection.mjs";
import fillHighlight from "./fill.mjs";
import headerHighlight from "./header.mjs";

var _staticRegister = staticRegister('highlight/types'),
    register = _staticRegister.register,
    getItem = _staticRegister.getItem;

register('active-header', activeHeaderHighlight);
register('area', areaHighlight);
register('cell', cellHighlight);
register('custom-selection', customSelection);
register('fill', fillHighlight);
register('header', headerHighlight);
/**
 * @param {string} highlightType The selection type.
 * @param {object} options The selection options.
 * @returns {Selection}
 */

function createHighlight(highlightType, options) {
  return getItem(highlightType)(_objectSpread({
    type: highlightType
  }, options));
}

export { createHighlight };