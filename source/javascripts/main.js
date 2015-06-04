var app = angular.module('blog', ['ngMaterial']);

app.controller('AppCtrl', ['$scope', '$mdSidenav', function ($scope, $mdSidenav) {
    $scope.toggleSidenav = function (menuId) {
        $mdSidenav(menuId).toggle();
    };

    //var menu = angular.element('#main-left').show();
    //console.log(menu);


}]).run(function ($mdSidenav) {


    //$mdSidenav('main-left').then(function(instance){
    //    console.log(instance);
    //    instance.show();
    //});

});