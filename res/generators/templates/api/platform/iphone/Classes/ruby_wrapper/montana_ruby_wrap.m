#import "../api/I<%= $cur_module.name %>.h"
//#import "api_generator/common/ruby_helpers.h"

#import "ruby/ext/rho/rhoruby.h"
#import "api_generator/iphone/CMethodResult.h"
#import "api_generator/iphone/CRubyConverter.h"

extern VALUE getRuby_<%= $cur_module.name %>_Module();

<% $iphone_types = {}
$iphone_types["STRING"] = 'NSString*'
$iphone_types["ARRAY"] = 'NSArray*'
$iphone_types["HASH"] = 'NSDictionary*'
$iphone_types["SELF_INSTANCE"] = 'id<'+$cur_module.name+'>' %>

@interface <%= $cur_module.name %>_RubyValueFactory : NSObject<IMethodResult_RubyObjectFactory> {
}

- (VALUE) makeRubyValue:(NSObject*)obj;
+ (<%= $cur_module.name %>_RubyValueFactory*) getSharedInstance;

@end

static <%= $cur_module.name %>_RubyValueFactory* our_<%= $cur_module.name %>_RubyValueFactory = nil;

@implementation <%= $cur_module.name %>_RubyValueFactory

- (VALUE) makeRubyValue:(NSObject*)obj {
    VALUE v = rho_ruby_get_NIL();
    if ([obj isKindOfClass:[NSString class]]) {
        // single objects id
        NSString* strRes = (NSString*)obj;
        v = rho_ruby_create_object_with_id( getRuby_<%= $cur_module.name %>_Module(), [strRes UTF8String] );
    }
    else if ([obj isKindOfClass:[NSArray class]]) {
        // list of IDs
        v = rho_ruby_create_array();
        NSArray* arrRes = (NSArray*)obj;
        int i;
        for (i = 0; i < [arrRes count]; i++) {
            NSString* strItem = (NSString*)[arrRes objectAtIndex:i];
            VALUE vItem = rho_ruby_create_object_with_id( getRuby_<%= $cur_module.name %>_Module(), [strItem UTF8String] );
            rho_ruby_add_to_array(v, vItem);
        }
    }
    return v;
}

+ (<%= $cur_module.name %>_RubyValueFactory*) getSharedInstance {
    if (our_<%= $cur_module.name %>_RubyValueFactory == nil) {
        our_<%= $cur_module.name %>_RubyValueFactory = [[<%= $cur_module.name %>_RubyValueFactory alloc] init];
    }
    return our_<%= $cur_module.name %>_RubyValueFactory;
}

@end


id<I<%= $cur_module.name %>> <%= $cur_module.name %>_makeInstanceByRubyObject(VALUE obj) {
    const char* szID = rho_ruby_get_object_id( obj );
    id<I<%= $cur_module.name %>Factory> factory = [<%= $cur_module.name %>FactorySingleton get<%= $cur_module.name %>FactoryInstance];
    return [factory get<%= $cur_module.name %>ByID:[NSString stringWithUTF8String:szID]];
}





<% $cur_module.methods.each do |module_method|

%>

<% is_callback_possible = module_method.is_run_in_thread || module_method.is_run_in_ui_thread || (module_method.has_callback != ModuleMethod::CALLBACK_NONE) %>

@interface <%= $cur_module.name %>_<%= module_method.name %>_caller_params : NSObject

@property (assign) NSArray* params;
@property (assign) id<I<%= $cur_module.name %>> item;
@property (assign) CMethodResult* methodResult;

+(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*) makeParams:(NSArray*)_params _item:(id<I<%= $cur_module.name %>>)_item _methodResult:(CMethodResult*)_methodResult;

@end

@implementation <%= $cur_module.name %>_<%= module_method.name %>_caller_params

@synthesize params,item,methodResult;

+(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*) makeParams:(NSArray*)_params _item:(id<I<%= $cur_module.name %>>)_item _methodResult:(CMethodResult*)_methodResult {
    <%= $cur_module.name %>_<%= module_method.name %>_caller_params* par = [[<%= $cur_module.name %>_<%= module_method.name %>_caller_params alloc] init];
    par.params = _params;
    par.item = _item;
    par.methodResult = _methodResult;
    return par;
}

@end


@interface <%= $cur_module.name %>_<%= module_method.name %>_caller : NSObject {

}
+(<%= $cur_module.name %>_<%= module_method.name %>_caller*) getSharedInstance;
+(void) <%= module_method.name %>:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params;
+(void) <%= module_method.name %>_in_thread:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params;
+(void) <%= module_method.name %>_in_UI_thread:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params;

@end

static <%= $cur_module.name %>_<%= module_method.name %>_caller* our_<%= $cur_module.name %>_<%= module_method.name %>_caller = nil;

@implementation <%= $cur_module.name %>_<%= module_method.name %>_caller

+(<%= $cur_module.name %>_<%= module_method.name %>_caller*) getSharedInstance {
    if (our_<%= $cur_module.name %>_<%= module_method.name %>_caller == nil) {
        our_<%= $cur_module.name %>_<%= module_method.name %>_caller = [[<%= $cur_module.name %>_<%= module_method.name %>_caller alloc] init];
    }
    return our_<%= $cur_module.name %>_<%= module_method.name %>_caller;
}

-(void) command_<%= module_method.name %>:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params {
    NSArray* params = caller_params.params;
    id<I<%= $cur_module.name %>> objItem = caller_params.item;
    CMethodResult* methodResult = caller_params.methodResult;

    <%
    method_line = "[objItem "+module_method.name
    if module_method.params.size > 0
        method_line = method_line + ":(#{$iphone_types[module_method.params[0].type]})params[0] "
        for i in 1..(module_method.params.size-1)
            method_line = method_line + "#{module_method.params[i].name}:(#{$iphone_types[module_method.params[i].type]})params[#{i}] "
        end
        method_line = method_line + "methodResult:methodResult "
    else
        method_line = method_line + ":methodResult "
    end
    method_line = method_line + "];"
    %>
    <%= method_line %>
}

+(void) <%= module_method.name %>:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params {
    [[<%= $cur_module.name %>_<%= module_method.name %>_caller getSharedInstance] command_getProps:caller_params];
}

+(void) <%= module_method.name %>_in_thread:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params {
    [[<%= $cur_module.name %>_<%= module_method.name %>_caller getSharedInstance] performSelectorInBackground:@selector(command_<%= module_method.name %>:) withObject:caller_params];
}

+(void) <%= module_method.name %>_in_UI_thread:(<%= $cur_module.name %>_<%= module_method.name %>_caller_params*)caller_params {
    [[<%= $cur_module.name %>_<%= module_method.name %>_caller getSharedInstance] performSelectorOnMainThread:@selector(command_<%= module_method.name %>:) withObject:caller_params waitUntilDone:NO];
}


@end


<%= "VALUE rb_"+$cur_module.name+"_"+module_method.name+"_Obj(int argc, VALUE *argv, id<I#{$cur_module.name}>objItem) {" %>

    CMethodResult* methodResult = [[CMethodResult alloc] init];

    NSObject* params[<%= module_method.params.size %>+1];
    NSString* callbackURL = nil;
    NSString* callbackParam = nil;
    BOOL method_return_result = YES;
    <%
     factory_params = "BOOL is_factory_param[] = { "
     module_method.params.each do |method_param|
        if method_param.type == MethodParam::TYPE_SELF
            factory_params = factory_params + "YES, "
        else
            factory_params = factory_params + "NO, "
        end
     end
     factory_params = factory_params + "NO };"
    %>
    <%= factory_params %>

    int i;

    // init
    for (i = 0; i < (<%= module_method.params.size %>); i++) {
        params[i] = [NSNull null];
    }

    // enumerate params
    for (int i = 0; i < (<%= module_method.params.size %>); i++) {
        if (argc > i) {
            // we have a [i] param !
            if (is_factory_param[i]) {
                params[i] = <%= $cur_module.name %>_makeInstanceByRubyObject(argv[i]);
            }
            else {
                params[i] = [[CRubyConverter convertFromRuby:argv[i]] retain];
            }
        }
    }

    NSMutableArray* params_array = [NSMutableArray arrayWithCapacity:(<%= module_method.params.size %>)];
    for (i = 0 ; i < (<%= module_method.params.size %>); i++) {
        [params_array addObject:params[i]];
    }

    <% if is_callback_possible %>
    // check callback
    if (argc >= (<%= module_method.params.size %>+1)) {
        VALUE callback = argv[<%= module_method.params.size %>];
        if (rho_ruby_is_string(callback)) {
            callbackURL = [((NSString*)[CRubyConverter convertFromRuby:callback]) retain];
        }
    }
    // check callback param
    if (argc >= (<%= module_method.params.size %>+2)) {
        VALUE callback_param = argv[<%= module_method.params.size %>+1];
        if (rho_ruby_is_string(callback_param)) {
            callbackParam = [((NSString*)[CRubyConverter convertFromRuby:callback_param]) retain];
        }
    }
    <% end %>

    <% if module_method.is_factory_method %>
    [methodResult setRubyFactory:[<%= $cur_module.name %>_RubyValueFactory getSharedInstance]];
    <% end %>

    if (callbackURL != nil) {
        // we have callback - method should not call setResult if method execute from current thread - only later or in UI or separated threads !!!
        [methodResult setRubyCallback:callbackURL];
        if (callbackParam != nil) {
            [methodResult setCallbackParam:callbackParam];
        }
        <% if module_method.is_run_in_ui_thread %>
        [<%= $cur_module.name %>_<%= module_method.name %>_caller <%= module_method.name %>_in_UI_thread:[<%= $cur_module.name %>_<%= module_method.name %>_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        <% else %>
        [<%= $cur_module.name %>_<%= module_method.name %>_caller <%= module_method.name %>_in_thread:[<%= $cur_module.name %>_<%= module_method.name %>_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        <% end %>
    }
    else {
        // we do not have callback
        <% if module_method.is_run_in_ui_thread %>
        [<%= $cur_module.name %>_<%= module_method.name %>_caller <%= module_method.name %>_in_UI_thread:[<%= $cur_module.name %>_<%= module_method.name %>_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        method_return_result = NO;
        <% else
             if module_method.is_run_in_thread %>
        [<%= $cur_module.name %>_<%= module_method.name %>_caller <%= module_method.name %>_in_thread:[<%= $cur_module.name %>_<%= module_method.name %>_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        method_return_result = NO;
             <% else %>
        [<%= $cur_module.name %>_<%= module_method.name %>_caller <%= module_method.name %>:[<%= $cur_module.name %>_<%= module_method.name %>_caller_params makeParams:params_array _item:objItem _methodResult:methodResult]];
        <% end
        end%>
    }
    VALUE resValue = rho_ruby_get_NIL();
    if ((callbackURL == nil) && (method_return_result)) {
        resValue = [methodResult toRuby];
    }
    return resValue;
}


<%= api_generator_MakeRubyMethodDecl($cur_module.name, module_method, module_method.access == ModuleMethod::ACCESS_STATIC)%> {
<% if module_method.access == ModuleMethod::ACCESS_STATIC %>
    id<I<%= $cur_module.name %>Factory> factory = [<%= $cur_module.name %>FactorySingleton get<%= $cur_module.name %>FactoryInstance];
    id<I<%= $cur_module.name %>Singleton> singleton = [factory get<%= $cur_module.name %>Singleton];

    //TODO: call static method
<% else %>
    id<I<%= $cur_module.name %>> item = <%= $cur_module.name %>_makeInstanceByRubyObject(obj);
    return <%= "rb_"+$cur_module.name+"_"+module_method.name %>_Obj(argc, argv, item);
<% end %>
}

<% if $cur_module.is_template_default_instance && module_method.access == ModuleMethod::ACCESS_INSTANCE
%><%= api_generator_MakeRubyMethodDecl($cur_module.name + "_def", module_method, true)%> {
    id<I<%= $cur_module.name %>Factory> factory = [<%= $cur_module.name %>FactorySingleton get<%= $cur_module.name %>FactoryInstance];
    id<I<%= $cur_module.name %>Singleton> singleton = [factory get<%= $cur_module.name %>Singleton];

    NSString* defID = [singleton getDefaultID];

    id<I<%= $cur_module.name %>> item = [factory get<%= $cur_module.name %>ByID:defID];
    return <%= "rb_"+$cur_module.name+"_"+module_method.name %>_Obj(argc, argv, item);
}

<% end %>

<% end %>


<% if $cur_module.is_template_default_instance %>
VALUE rb_<%= $cur_module.name %>_s_default(VALUE klass)
{
    id<I<%= $cur_module.name %>Factory> factory = [<%= $cur_module.name %>FactorySingleton get<%= $cur_module.name %>FactoryInstance];
    id<I<%= $cur_module.name %>Singleton> singleton = [factory get<%= $cur_module.name %>Singleton];

    NSString* defID = [singleton getDefaultID];

    return rho_ruby_create_object_with_id( klass, [defID UTF8String] );
}

VALUE rb_<%= $cur_module.name %>_s_setDefault(VALUE klass, VALUE valObj)
{
    const char* szID = rho_ruby_get_object_id( valObj );
    id<I<%= $cur_module.name %>Factory> factory = [<%= $cur_module.name %>FactorySingleton get<%= $cur_module.name %>FactoryInstance];
    id<I<%= $cur_module.name %>Singleton> singleton = [factory get<%= $cur_module.name %>Singleton];

    [singleton setDefaultID:[NSString stringWithUTF8String:szID]];

    return rho_ruby_get_NIL();
}
<% end %>


