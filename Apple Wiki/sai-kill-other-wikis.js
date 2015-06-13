Event.observe(window, 'load', function() { 
    // add another header link (to saico.com) by manipulating the DOM 
    // using script.aculo.us Builder 
    // we'll just insert it before the search button 
    if ($('linkSearch')) { 
        $('linkSearch').parentNode.insertBefore(Builder.node('li', {id:'linkSAI'}, [ 
            Builder.node('a', {href:'http://www.saico.com'}, 'sai') 
        ]), $('linkSearch')); 
    } 
    // change the Other Wikis link to something else 
    if ($('groups_users_button')) { 
        $('groups_users_button').down('a').href = 'http://www.saico.com/'; 
    } 
});