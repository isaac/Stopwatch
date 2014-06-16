#if TARGET_OS_IPHONE

#import <AIXMLSerialization/DDXML.h>

#ifndef NSXMLNode
#define NSXMLNode DDXMLNode
#endif
#ifndef NSXMLElement
#define NSXMLElement DDXMLElement
#endif
#ifndef NSXMLDocument
#define NSXMLDocument DDXMLDocument
#endif

#ifndef NSXMLNodeKind                                                   
#define NSXMLInvalidKind                 DDXMLInvalidKind              
#define NSXMLDocumentKind                DDXMLDocumentKind             
#define NSXMLElementKind                 DDXMLElementKind              
#define NSXMLAttributeKind               DDXMLAttributeKind            
#define NSXMLNamespaceKind               DDXMLNamespaceKind            
#define NSXMLProcessingInstructionKind   DDXMLProcessingInstructionKind
#define NSXMLCommentKind                 DDXMLCommentKind              
#define NSXMLTextKind                    DDXMLTextKind                 
#define NSXMLDTDKind                     DDXMLDTDKind                  
#define NSXMLEntityDeclarationKind       DDXMLEntityDeclarationKind    
#define NSXMLAttributeDeclarationKind    DDXMLAttributeDeclarationKind 
#define NSXMLElementDeclarationKind      DDXMLElementDeclarationKind   
#define NSXMLNotationDeclarationKind     DDXMLNotationDeclarationKind  

#define NSXMLNodeKind DDXMLNodeKind;
#endif

#ifndef NSXMLNodeOptionsNone
#define NSXMLNodeOptionsNone         DDXMLNodeOptionsNone        
#define NSXMLNodeExpandEmptyElement  DDXMLNodeExpandEmptyElement 
#define NSXMLNodeCompactEmptyElement DDXMLNodeCompactEmptyElement
#define NSXMLNodePrettyPrint         DDXMLNodePrettyPrint        
#endif

#ifndef DDXMLDocumentContentKind
#define NSXMLDocumentXMLKind   DDXMLDocumentXMLKind 
#define NSXMLDocumentXHTMLKind DDXMLDocumentXHTMLKind
#define NSXMLDocumentHTMLKind  DDXMLDocumentHTMLKind
#define NSXMLDocumentTextKind  DDXMLDocumentTextKind

#define NSXMLDocumentContentKind DDXMLDocumentContentKind
#endif

#endif

#import <AIXMLSerialization/AIXMLDocumentSerialize.h>
#import <AIXMLSerialization/AIXMLElementSerialize.h>