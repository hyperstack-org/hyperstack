
import React from 'react';
import ReactDOM from 'react-dom';
import * as History from 'history';
import * as ReactRouter from 'react-router';
import * as ReactRouterDOM from 'react-router-dom';
import * as ReactRailsUJS from 'react_ujs';
import ActionCable from 'actioncable';

global.React = React;
global.ReactDOM = ReactDOM;
global.History = History;
global.ReactRouter = ReactRouter;
global.ReactRouterDOM = ReactRouterDOM;
global.ReactRailsUJS = ReactRailsUJS;
global.ActionCable = ActionCable;

import init_app from 'hyperstack_webpack_loader.rb';

init_app();
Opal.load('hyperstack_webpack_loader');
if (module.hot) {
    module.hot.accept('./app.js', function () {
        console.log('Accepting the updated app module!');
    })
}
